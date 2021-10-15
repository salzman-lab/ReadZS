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
binSize <- as.numeric(args[2])
ont_cols <- args[3]
n_genes <- args[4]
outputDir <- args[5]
sample_name <- args[6]

ont_cols <- unlist(strsplit(ont_cols, ", "))
n_onts <- 2

pval_windows <- fread(all_pvals, header=T)

windows = c()
for (i in pval_windows$window) {
  if (! i %in% windows) windows <- c(windows, i)
}

windows_list <- head(windows, as.numeric(n_genes))

ind = 1
for (target_window in windows_list){
  windows_data <- data.table()

  subset <- pval_windows[window==target_window,]
  subset <- subset[order(-median_z_scaled),]

  if (nrow(subset) < 4) {
    onts_list <- subset
  } else {
    onts_top <- head(subset, n_onts)
    onts_bottom <- tail(subset, n_onts)
    onts_list <- rbind(onts_top, onts_bottom)
  }

  target_chr <- strsplit(target_window, "_", fixed=TRUE)[[1]][1]
  bin <- strsplit(target_window, "_", fixed=TRUE)[[1]][2]
  target_window_end <- as.numeric(bin) * binSize
  target_window_start <- target_window_end - binSize

  target_gene <- paste(unique(onts_list$gene), collapse='_')
  target_chi2 <- unique(onts_list$chi2_p_val)
  target_pval <- unique(onts_list$perm_p_val)


  for (i in 1:nrow(onts_list)) {
    target_ont <- onts_list[i, ontology]
    target_median <- onts_list[i, median_z_scaled]
    #total_counts <- onts_list[i, sum_counts_per_window_per_ont]

    counts_file <- paste(
      outputDir, "/counts/", sample_name, "_", target_chr, ".txt",
      sep=""
    )

    zscore_file <- paste(
      outputDir, "/zscore/", sample_name, "_", target_chr, ".zscore",
      sep=""
    )

    all_counts <- fread(counts_file, header=F)
    names(all_counts) <- c("cell_id", "chr", "pos", "read_strand", "count", "channel", "window")
    counts <- all_counts[window==target_window, ]

    all_zscores <- fread(zscore_file, header=T)
    all_zscores <- all_zscores[, ontology:=Reduce(function(...) paste(..., sep="___"), .SD[, mget(ont_cols)])]
    zscores <- all_zscores[window==target_window & ontology==target_ont, ]

    data <- merge(unique(counts), unique(zscores), by=c("window","cell_id", "read_strand"), all=F)

    total_cells <- length(unique(data$cell_id))
    total_counts <- sum(data$count.x)

    data <- data[, pos_bin_size := 10]
    binsize2 <- 10

    data <- data[, pos_round := pos_bin_size * trunc(pos/pos_bin_size)]

    subset_list_1 <- c("count.x", "pos_round", ont_cols)
    subset_list_2 <- c("pos_round", ont_cols)
    subset_list_3 <- c("pos_round", "counts_sum", ont_cols)

    data <- data[, subset_list_1, with=FALSE]
    data <- data[, counts_sum := sum(count.x), by=subset_list_2]
    data <- data[, subset_list_3, with=FALSE]
    data <- data[!duplicated(data)]

    data <- data[, percent := 100 * counts_sum / sum(counts_sum), by=c(ont_cols)]
    data <- data[, median_z_scaled := target_median]
    data <- data[, metrics := paste("reads = ", total_counts, ", cells = ", total_cells, sep="")]

    windows_data <- rbind(windows_data, data)
  }

  windows_data <- windows_data[, chromosome := target_chr]
  windows_data <- windows_data[, window_start := target_window_start]
  windows_data <- windows_data[, window_end := target_window_end]

  out_stem <- paste("rank", ind, target_window, target_gene, "chi2", target_chi2, "pval", target_pval, sep="_")
  out_file <- paste(out_stem, ".plotterFile", sep="")

  print(target_gene)
  print(target_chi2)
  print(target_pval)

  write.table(windows_data, out_file, sep='\t', row.names=F, col.names=T, quote=F)

  ind <- ind + 1
}
