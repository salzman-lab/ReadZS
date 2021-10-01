#!/usr/bin/env Rscript


## PURPOSE: takes in Z scores with metadata. Calculates median Z score by window and
## ontology (combination of metadata), and determines which windows have significantly
## different median Z-scores in different ontologies. Outputs a table of all windows with
## calculable median Z scores, and a table of only the significant windows.

if (!require("data.table")) {
  install.packages("data.table", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(data.table)
}
if (!require("tidyr")) {
  install.packages("tidyr", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(tidyr)
}
if (!require("PEIP")) {
  install.packages("PEIP", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(PEIP)
}

library(PEIP)

### Newest version 4.22.21
### === ARGUMENTS ===

args <- commandArgs(TRUE)
input_file <- args[1]
ontology_cols <- args[2]
min_cells_per_windowont <- as.numeric(args[3])
min_cts_per_cell <- as.numeric(args[4])
n_permutations <- as.numeric(args[5])
output_medians_real <- args[6]
output_pvals <- args[7]


### === HARDCODED VALUES ===

alpha_value <- 0.05  # set this value for BH correction
min_fraction_annotated <- 0.5  # min fraction of cells w/ ontology annotation to include a gene
set.seed(42)

### ========================

## Read in table of Z scores
z_table <- fread(input_file, header=T)


## Create ontology groupings based on columns in argument
ontology_cols = unlist(strsplit(ontology_cols, ", "))
z_table[is.na(z_table)] <- "ANNOTATE_NA"
z_table <- z_table %>% unite('ontology', c(all_of(ontology_cols)), sep="___", remove=FALSE)


## Filter: only keep windows with at least min_fraction_annotated % of cells annotated
z_table[, has_ann := ifelse((ontology %like% "ANNOTATE_NA"), 0, 1)]
z_table[, cells_per_window := uniqueN(cell_id), by=window]
z_table[, percent_annotated := sum(has_ann) / cells_per_window, by=window]
z_table <- z_table[percent_annotated > min_fraction_annotated,]


## Filter: only keep ontologies that are not NA
z_table <- z_table[!(ontology %like% "ANNOTATE_NA"),]


## Filter: only keep window/cells where z score could be calculated
z_table <- z_table[!is.na(z_scaled),]


## Filter: only keep cell-window pairs w/  minimum # counts of a window per cell
z_table[, total_count := sum(count), by=c("cell_id", "window")]
z_table <- z_table[total_count >= min_cts_per_cell, ]


## Filter: only keep cells /w minimum number of cells per window + ontology
z_table <- z_table[, cells_per_window_ont := .N, by=c("window", "ontology")]
z_table <- z_table[cells_per_window_ont > min_cells_per_windowont,]


## Filter: only keep windows with at least two ontologies
z_table <- z_table[, num_of_onts := uniqueN(ontology), by=window]
z_table <- z_table[num_of_onts > 1,]


## Add columns to summarize the counts
z_table[, sum_counts_per_window_per_ont := sum(count), by=c("window","ontology")] # Add column to aggregate(sum) counts per window per ontology
z_table[, med_counts_per_window_per_ont := median(count), by=c("window","ontology")] # Add column to aggregate(median) counts per window per ontology
z_table <- z_table[, c("has_ann", "cells_per_window", "percent_annotated", "total_count", "num_of_onts") := NULL]  # Remove extra columns





## Calculate chi^2 p-value. First step in Romano p-value approach
z_table <- z_table[, real_window_ont := paste(window, ontology, sep="xxx")]  # make a column for the real window-ont pairing of each cell/window line
z_table <- z_table[, median_z_scaled := median(z_scaled), by = c("real_window_ont", "window")]  # calculate median(z) by window-ont
z_table <- z_table[, window_ont_var := var(z_scaled), by = c("real_window_ont", "window")]  # calculate var(z) by window-ont
z_table <- z_table[, num_to_sum :=  cells_per_window_ont * median_z_scaled / window_ont_var]  # making a column for what we need to add up to make the numerator...
z_table <- z_table[, num := sum(num_to_sum), by=window]  # sum to get the numerator
z_table <- z_table[, denom_to_sum := cells_per_window_ont / window_ont_var ]  # making a column for what we need to add up to make the denominator..
z_table <- z_table[, denom := sum(denom_to_sum), by=window]  # sum to get the denominator
z_table <- z_table[, const := num / denom]
z_table <- z_table[, to_sum := (cells_per_window_ont / window_ont_var) * ((median_z_scaled - const) ^ 2)]
z_table <- z_table[, test_stat := sum(to_sum), by=window]  # test_stat is the T_n,1
z_table <- z_table[, deg_freedom := .N, by=window]  # degrees of freedom = how many onts per window - 1
z_table <- z_table[, chi2_p_val := 1 - chi2cdf(test_stat, deg_freedom - 1), by=window]
z_table <- z_table[, c("num_to_sum", "num", "denom_to_sum", "denom", "const", "to_sum", "deg_freedom", "window_ont_var", "cells_per_window_ont") := NULL]

print("Finished making z_table.")



## For windows with ch^2 p-val < 0.05, permute the ontology labels of the cells and calculate test statistic that way.

real_ont_labels <- copy(z_table)
real_ont_labels <- real_ont_labels[chi2_p_val < alpha_value,]  # select only windows w/ chi^2 p-value less than 0.05

scrambled_ont_labels <- copy(real_ont_labels)  # make a copy of the table to scramble the ontology assignments
scrambled_ont_labels <- scrambled_ont_labels[, ontology_scrambled := sample(ontology), by=c("window")]  # permute the ont labels, within a window and quantile
scrambled_ont_labels <- scrambled_ont_labels[, scrambled_window_ont := paste(window, ontology_scrambled, sep="xxx")]  # make a column for the window + scrambled-ont pairing assigned to that cell/window
scrambled_ont_labels <- scrambled_ont_labels[, scrambled_median := median(z_scaled, na.rm=T), by = c("scrambled_window_ont", "window")]
scrambled_ont_labels <- scrambled_ont_labels[, scrambled_ont_var := var(z_scaled, na.rm=T), by = c("scrambled_window_ont", "window")]
scrambled_ont_labels <- scrambled_ont_labels[, scr_cells_per_window_ont := .N, by=c("window", "scrambled_window_ont")]  # add col w/ # of cells per window-ont pair
scrambled_ont_labels <- scrambled_ont_labels[, num_to_sum :=  scr_cells_per_window_ont * scrambled_median / scrambled_ont_var]  # making a column for what we need to add up to make the numerator...
scrambled_ont_labels <- scrambled_ont_labels[, num := sum(num_to_sum), by=window]  # sum to get the numerator
scrambled_ont_labels <- scrambled_ont_labels[, denom_to_sum := scr_cells_per_window_ont / scrambled_ont_var ]  # making a column for what we need to add up to make the denominator..
scrambled_ont_labels <- scrambled_ont_labels[, denom := sum(denom_to_sum), by=window]  # sum to get the denominator
scrambled_ont_labels <- scrambled_ont_labels[, const := num / denom]
scrambled_ont_labels <- scrambled_ont_labels[, to_sum := (scr_cells_per_window_ont / scrambled_ont_var) * ((scrambled_median - const) ^ 2)]
scrambled_ont_labels <- scrambled_ont_labels[, .(scr_test_stat = sum(to_sum)), .(window)]  # test_stat is the T_n,1. Calculated by window

print("Finished making first permutation.")

for (i in seq(2, n_permutations)) {  # repeat permuting process N-1 more times, and append the additional medians
    temp_scrambled <- copy(real_ont_labels)
    temp_scrambled <- temp_scrambled[, ontology_scrambled := sample(ontology), by=c("window")]
    temp_scrambled <- temp_scrambled[, scrambled_window_ont := paste(window, ontology_scrambled, sep="xxx")]
    temp_scrambled <- temp_scrambled[, scrambled_median := median(z_scaled), by = c("scrambled_window_ont", "window")]
    temp_scrambled <- temp_scrambled[, scrambled_ont_var := var(z_scaled), by = c("scrambled_window_ont", "window")]
    temp_scrambled <- temp_scrambled[, scr_cells_per_window_ont := .N, by=c("window", "scrambled_window_ont")]
    temp_scrambled <- temp_scrambled[, num_to_sum :=  scr_cells_per_window_ont * scrambled_median / scrambled_ont_var]
    temp_scrambled <- temp_scrambled[, num := sum(num_to_sum), by=window]
    temp_scrambled <- temp_scrambled[, denom_to_sum := scr_cells_per_window_ont / scrambled_ont_var ]
    temp_scrambled <- temp_scrambled[, denom := sum(denom_to_sum), by=window]
    temp_scrambled <- temp_scrambled[, const := num / denom]
    temp_scrambled <- temp_scrambled[, to_sum := (scr_cells_per_window_ont / scrambled_ont_var) * ((scrambled_median - const) ^ 2)]
    temp_scrambled <- temp_scrambled[, .(scr_test_stat = sum(to_sum)), .(window)]

    scrambled_ont_labels <- rbind(scrambled_ont_labels, temp_scrambled)
    temp_scrambled <- NULL
}

print("Finished all permutations.")

real_ont_labels <- unique(real_ont_labels[, c("window", "test_stat")])


## Compare the real test_stat to the scrambled ones to calculate p-value
compare_table <- merge(scrambled_ont_labels, real_ont_labels, by="window", all.x=T)  # merge real and scrambled tables by window
compare_table[, scr_less_than_real := ifelse(scr_test_stat < test_stat, 1, 0)]  # make identity function based on whether the scrambled test stat is smaller than the real one
compare_table[, cdf_perm := (sum(scr_less_than_real)) / n_permutations, by=window]
compare_table[, perm_p_val := 2 * min(cdf_perm, (1 - cdf_perm)), by=window]  # calculate permutation p=value: 2-sided to quantify whether the real value is extreme in either direction


## Benjamini-Hochberg correction:
compare_table[, num_tests := uniqueN(real_ont_labels), by=window]  # number of tests = how many onts per window
compare_table[, pval_rank := frank(perm_p_val, ties.method="dense"), by=window]  # assign ranks to p-values, with same rank for the same value
compare_table[, BH_crit_val := (pval_rank / num_tests) * alpha_value]  # calculate the critical value for each window
largest_pval <- max(compare_table[perm_p_val < BH_crit_val, ]$perm_p_val)  # among p-values less than corresponding critical value, which one is max
compare_table[, significant := ifelse(perm_p_val <= largest_pval, TRUE, FALSE)]  # only significant if p-value is less than largest p-value allowed


## Merge table of p-values with table of all medians
compare_table <- unique(compare_table[, c("window", "perm_p_val", "significant")])  # get unique rows of p-value table
z_table <- merge(z_table, compare_table, by=c("window"), all.x=T)  # merge p-value table and medians table
z_table[, significant := ifelse(significant, TRUE, FALSE)]  # replace NAs in significant column with FALSE


## Remove unnecessary cols and remove duplicate rows
essential_cols <- c("window", "ontology", "sum_counts_per_window_per_ont", "med_counts_per_window_per_ont", "median_z_scaled", "chi2_p_val", "perm_p_val", "significant")
z_table <- z_table[, ..essential_cols]
z_table <- unique(z_table)


## Calculate range of medians by window: used as "effect size" to rank windows for plotting
z_table[, medians_range := max(median_z_scaled) - min(median_z_scaled), by=window]
z_table <- z_table[order(-medians_range, median_z_scaled)]


## Save table that includes all medians irrespective of p-val
write.table(z_table, file=output_medians_real, sep="\t", row.names=F, quote=F, col.names=T)


## Save table with only significant windows
z_table <- z_table[significant==T,]
write.table(z_table, file=output_pvals, sep="\t", row.names=F, col.names=T, quote=F)
