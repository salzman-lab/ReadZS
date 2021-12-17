#!/usr/bin/env Rscript

library(data.table)
library(tidyr)


args <- commandArgs(TRUE)
signif_medians <- args[1]
counts_file <- args[2]
zscore_file <- args[3]
binSize <- as.numeric(args[4])
ont_cols <- args[5]
n_genes <- args[6]

ont_cols <- unlist(strsplit(ont_cols, ", "))
n_onts <- 2

pval_windows <- fread(signif_medians, header=T)

all_counts <- fread(counts_file, header=T)

all_zscores <- fread(zscore_file, header=T)
all_zscores <- all_zscores[, ontology:=Reduce(function(...) paste(..., sep="___"), .SD[, mget(ont_cols)])]

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
    onts_list < -rbind(onts_top, onts_bottom)
  }

  target_chr <- strsplit(target_window, "_", fixed=TRUE)[[1]][1]
  bin <- strsplit(target_window, "_", fixed=TRUE)[[1]][3]
  target_window_end <- as.numeric(bin) * binSize
  target_window_start <- target_window_end - binSize

  for (i in 1:nrow(onts_list)) {
    target_ont <- onts_list[i, ontology]
    target_median <- onts_list[i, median_z_scaled]

    counts <- all_counts[window==target_window, ]

    zscores <- all_zscores[window==target_window & ontology==target_ont, ]

    data <- merge(unique(counts), unique(zscores), by=c("window", "sample_ID"), all=F)

    data <- data[, pos_bin_size := 10]
    data$pos <- as.numeric(data$pos)

    binsize2 <- 10
    data <- data[, pos_round := pos_bin_size * trunc(pos/pos_bin_size)]

    subset_list_1 <- c("count.x", "pos_round", ont_cols)
    subset_list_2 <- c("pos_round", ont_cols)
    subset_list_3 <- c("pos_round", "counts_sum", ont_cols)

    data$count.x <- as.numeric(data$count.x)

    data <- data[, subset_list_1, with=FALSE]
    data <- data[, counts_sum := sum(count.x), by=subset_list_2]
    data <- data[, subset_list_3, with=FALSE]
    data <- data[!duplicated(data)]

    data <- data[, percent := 100 * counts_sum / sum(counts_sum), by=c(ont_cols)]
    data <- data[, median_z_scaled := target_median]

    windows_data <- rbind(windows_data, data)
  }

  windows_data <- windows_data[, chromosome := target_chr]
  windows_data <- windows_data[, window_start := target_window_start]
  windows_data <- windows_data[, window_end := target_window_end]

  out_stem <- paste("rank", ind, target_window, sep="_")
  out_file <- paste(out_stem, ".txt", sep="")

  write.table(windows_data, out_file, sep='\t', row.names=F, col.names=T, quote=F)

  ind <- ind + 1
}
