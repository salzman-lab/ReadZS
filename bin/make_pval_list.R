#!/usr/bin/env Rscript

if (!require("data.table")) {
  install.packages("data.table", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(data.table)
}
if (!require("tidyr")) {
  install.packages("tidyr", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(tidyr)
}
if (!require("stringr")) {
  install.packages("stringr", dependencies = TRUE, repos = "http://cran.us.r-project.org")
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
    "pval",
    "significant",
    "medians_range"
  )

  # If SS2 i.e. no strand info in annotation file, remove strand info from windows
  if (!("strand" %in% names(genes))) {
    pvals[, window := str_replace(window, "_minus", "")]
    pvals[, window := str_replace(window, "_plus", "")]
  }

  pvals <- pvals[, max_med := max(median_z_scaled), by=window]
  pvals <- pvals[, min_med := min(median_z_scaled), by=window]
  pvals <- pvals[(min_med<0) & (max_med>0),]

  genes_only <- genes[, c("gene", "window")]
  all_pvals <- merge(pvals, genes_only, by="window", all.x=T)

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

  ann_pvals <- merge(windows, genes, by="window", all.x=T)
  ann_pvals <- ann_pvals[order(rank),]

  ann_pvals <- ann_pvals[, strand := ifelse(window %like% "plus", "+", "-")]
  ann_pvals <- ann_pvals[, c("window", "rank", "gene", "chr", "start", "end", "strand")]

  chi2_list <- list()
  pval_list <- list()
  for (i in 1:nrow(ann_pvals)){
    target_window <- ann_pvals[i, window]
    target_pval <- unique(pvals[window==target_window, pval])
    pval_list <- c(pval_list, target_pval)
  }
  ann_pvals <- cbind(ann_pvals, unlist(pval_list))
  names(ann_pvals) <- c("window", "rank", "gene", "chr", "start", "end", "strand", "pval")

  ann_pvals <- ann_pvals[, toString(unique(gene)), by = list(window, rank, chr, start, end, strand, pval)]

  names(ann_pvals) <- c("window", "rank", "chr", "start", "end", "strand", "pval", "gene")
  ann_pvals <- ann_pvals[, c("window", "rank", "gene", "chr", "start", "end", "strand", "pval")]

  write.table(ann_pvals, outfile_annPvals, sep='\t', row.names=F, col.names=T, quote=F)

}
