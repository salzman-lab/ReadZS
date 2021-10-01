#!/usr/bin/env Rscript

if (!require("data.table")) {
  install.packages("data.table", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(data.table)
}
if (!require("tidyr")) {
  install.packages("tidyr", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(tidyr)
}

args <- commandArgs(TRUE)
all_pvals <- args[1]
gene_windows <- args[2]
outfile_allPvals <- args[3]
outfile_annPvals <- args[4]

genes <- fread(gene_windows, header=T)

pvals <- fread(all_pvals, header=T)
if (nrow(pvals) > 0) {  # only keep processing files that are not empty
  names(pvals) <- c(
    "window",
    "ontology",
    "sum_counts_per_window_per_ont",
    "med_counts_per_window_per_ont",
    "median_z_scaled",
    "chi2_p_val",
    "perm_p_val",
    "significant",
    "medians_range"
  )

  pvals <- pvals[, max_med := max(median_z_scaled), by=window]
  pvals <- pvals[, min_med := min(median_z_scaled), by=window]
  pvals <- pvals[(min_med<0) & (max_med>0),]

  pvals <- pvals[, chr_window := sub("_minus", "", window)]
  pvals <- pvals[, chr_window := sub("_plus", "", chr_window)]

  genes_only <- genes[, c("gene", "chr_window")]
  all_pvals <- merge(pvals, genes_only, by="chr_window", all.x=T)

  all_pvals <- all_pvals[order(-medians_range),]

  write.table(all_pvals, outfile_allPvals, sep='\t', row.names=F, col.names=T, quote=F)

  windows = c()
  for (i in all_pvals$window) {
    if (! i %in% windows) {
      windows <- c(windows, i)
    }
  }

  windows <- data.table(matrix(unlist(windows), ncol=1, byrow = TRUE))
  names(windows) <- c("window")
  windows$rank <- seq.int(nrow(windows))
  windows <- windows[, chr_window := sub("_minus", "", window)]
  windows <- windows[, chr_window := sub("_plus", "", chr_window)]

  ann_pvals <- merge(windows, genes, by="chr_window", all.x=T)

  ann_pvals <- ann_pvals[order(rank),]

  ann_pvals <- ann_pvals[, strand := ifelse(window %like% "plus", "+", "-")]
  ann_pvals <- ann_pvals[, c("window", "rank", "gene", "chr", "start", "end", "strand")]

  chi2_list <- list()
  pval_list <- list()
  for (i in 1:nrow(ann_pvals)){
    target_window <- ann_pvals[i, window]
    target_chi2 <- unique(pvals[window==target_window, chi2_p_val])
    target_pval <- unique(pvals[window==target_window, perm_p_val])
    chi2_list <- c(chi2_list, target_chi2)
    pval_list <- c(pval_list, target_pval)
  }
  ann_pvals <- cbind(ann_pvals, unlist(chi2_list))
  ann_pvals <- cbind(ann_pvals, unlist(pval_list))
  names(ann_pvals) <- c("window", "rank", "gene", "chr", "start", "end", "strand", "chi2_pval", "perm_pval")

  ann_pvals <- ann_pvals[, toString(unique(gene)), by = list(window, rank, chr, start, end, strand, chi2_pval, perm_pval)]

  names(ann_pvals) <- c("window", "rank", "chr", "start", "end", "strand", "chi2_pval", "perm_pval", "gene")
  ann_pvals <- ann_pvals[, c("window", "rank", "gene", "chr", "start", "end", "strand", "chi2_pval", "perm_pval")]

  write.table(ann_pvals, outfile_annPvals, sep='\t', row.names=F, col.names=T, quote=F)

}
