#!/usr/bin/env Rscript

library(data.table)

args <- commandArgs(TRUE)

input_file <- args[1]
output_file <- args[2]
metadata_file <- args[3]
# zscores_only <- args[4]

## Read in data and add appropriate columns
m <- fread(
    input_file,
    header=T,
    colClasses=c('character', 'character', 'numeric', 'character', 'character')
)

## Calculating Z scores
## Rank and mean rank by window
m[, rankpos:=frankv(pos,ties.method="dense"), by=list(window)]
m$count <- as.numeric(m$count)
print(head(m))
m[, sumCount:=sum(count),by=list(pos, window)]  # number of reads at each position
m[, nwindow:=sum(count),by=list(window)]  # total number of reads for a window
m[, mu:=sum(as.numeric(count) * as.numeric(rankpos))/nwindow, by = list(window)]  # mean rank for a window
m[, sd:= sqrt(sum((rankpos - mu)^2 * count) / nwindow), by = list(window)]  # sd = (rank - mean)^2 * P(rank)

## Calculate per cell average divided by sd:
m[, totCountPerCell :=sum(count), by=list(sample_ID, window)]  # total # reads for a cell
m[, z_scaled := sum(count * rankpos - count * mu) / (sd * totCountPerCell), by=list(sample_ID, window)]

# exclude rows with Inf
m[, sdAll := sd(z_scaled[is.finite(z_scaled)])]
m[, sdwindow := sd(z_scaled[is.finite(z_scaled)]), by = list(window)]
m[, sdDiff := sdwindow - sdAll]
m <- m[is.finite(sd) & is.finite(z_scaled) & is.finite(sdAll) & is.finite(sdwindow)]

## Aggregate by cell, then save table with Z scores and all new cols
m2 <- m[, lapply(.SD, sum), by = .(seqname, sample_ID, window, z_scaled), .SDcols = "count"]

ann <- fread(metadata_file, header=T)
output <- merge(x=m2, y=ann, by="sample_ID", all.x=T)

write.table(output, file=output_file, quote=F, sep="\t", col.names=T, row.names=F)
