#!/usr/bin/env Rscript

if (!require("data.table")) {
  install.packages("data.table", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(data.table)
}

args <- commandArgs(TRUE)

input_file <- args[1]
output_file <- args[2]
metadata_file <- args[3]
zscores_only <- args[4]

## Read in data and add appropriate columns
m <- fread(input_file, header=F)
names(m) <- c("cell_id", "chrom", "pos", "read_strand", "count", "channel", "window")

## Calculating Z scores
## Rank and mean rank by window
m[, rankpos:=frankv(pos,ties.method="dense"), by=list(window)]
m[, sumCount:=sum(count),by=list(pos, window)]  # number of reads at each position
m[, nwindow:=sum(count),by=list(window)]  # total number of reads for a window
m[, mu:=sum(as.numeric(count) * as.numeric(rankpos))/nwindow, by = list(window)]  # mean rank for a window
m[, sd:= sqrt(sum((rankpos - mu)^2 * count) / nwindow), by = list(window)]  # sd = (rank - mean)^2 * P(rank)

## Calculate per cell average divided by sd:
m[, totCountPerCell :=sum(count), by=list(cell_id, window)]  # total # reads for a cell
m[, z_scaled := sum(count * rankpos - count * mu) / (sd * totCountPerCell), by=list(cell_id, window)]

# exclude rows with Inf
m[, sdAll := sd(z_scaled[is.finite(z_scaled)])]
m[, sdwindow := sd(z_scaled[is.finite(z_scaled)]), by = list(window)]
m[, sdDiff := sdwindow - sdAll]
m <- m[is.finite(sd) & is.finite(z_scaled) & is.finite(sdAll) & is.finite(sdwindow)]

## Aggregate by cell, then save table with Z scores and all new cols
m2 <- m[, lapply(.SD, sum), by = .(chrom, cell_id, read_strand, window, channel, z_scaled), .SDcols = "count"]

if (zscores_only == 'true') {
    write.table(m2, file=output_file, quote=F, sep="\t", col.names=T, row.names=F)
} else if (zscores_only == 'false' ) {
    ## Read in annotation files
    ann <- fread(metadata_file, header=T)

    ## Merge
    output <- merge(x=m2, y=ann, by="cell_id", all.x=T)

    write.table(output, file=output_file, quote=F, sep="\t", col.names=T, row.names=F)
}

