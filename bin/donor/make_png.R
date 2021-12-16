#!/usr/bin/env Rscript

library(data.table)
library(Gviz)

args <- commandArgs(TRUE)
input_file <- args[1]
ont_cols <- args[2]

options(ucscChromosomeNames=FALSE)

ont_cols <- unlist(strsplit(ont_cols, ", "))
data <-fread(input_file, header=T)

chr <- unique(data$chromosome)
window_start <- unique(data$window_start)
window_end <- unique(data$window_end)

data <- data[, ontology:=Reduce(function(...) paste(..., sep="___"), .SD[, mget(ont_cols)])]
data <- data[, z_label := paste("Median Z-Score = ", round(median_z_scaled, 3), sep="")]
data <- data[, label_col := paste(ontology, z_label, sep="; ")]

data <- data[, seqnames := chr]
data <- data[, end := pos_round+1]
data <- data[,c("pos_round", "end", "percent", "seqnames", "label_col")]
names(data) <- c("start", "end", "percent", "seqnames","label_col")

name_list<-unique(data$label_col)
data$label_col <- factor(data$label_col, levels=unique(data$label_col))

tracks <- split(data[, c("start","end","percent","seqnames")], data$label_col)
plot_list = c()

padder <- data.table()
padder <- padder[, start := seq(window_start, window_end, 10)]
padder <- padder[, end := start + 10]
padder <- padder[, percent := 0]

ind=1
for (track in tracks){
  df <- data.frame(track)
  names(df) <-  c("start", "end","percent","seqnames")
  for (j in 1:nrow(padder)){
    target_start <- padder[j, start]
    target_end <- target_start + 10
    if (target_start %in% df$start == FALSE){
      new_row <- c(target_start, target_end, 0, chr)
      df <- rbind(df, new_row)
    }
  }
  xranges <- makeGRangesFromDataFrame(df, TRUE)
  xtrack<-DataTrack(
    xranges,
    name=name_list[ind],
    chromosome=chr,
    from=window_start,
    to=window_end,
    cex.axis=0.01)
  plot_list <- c(plot_list, xtrack)
  ind=ind+1
}


outfile <- sub(".txt", ".png", input_file)
png(outfile, width = 800, height = 800)

plotTracks(
  plot_list,
  from=window_start,
  to=window_end,
  shape="arrow",
  exonAnnotation='symbol',
  fontcolor.exon="black",
  fontcolor.title="black",
  type='a',
  legend=TRUE,
  cex.legend=.8,
  cex.title=1.5
)

dev.off()
