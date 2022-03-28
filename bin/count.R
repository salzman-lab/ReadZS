#!/usr/bin/env Rscript

if (!require("data.table")) {
  install.packages("data.table", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(data.table)
}

args<-commandArgs(TRUE)
input_file <- args[1]
basename <- args[2]
libType <- args[3]
binSize <- as.numeric(args[4])




## To put into arguments eventually...
geneVersion <- T
#gene_bed_path <- "/scratch/groups/horence/Elisabeth/intron_zscore/Arabidopsis/ref_files/Arabidopsis_3UTR_forReadZS.tsv"
#gene_bed_path <- "/scratch/groups/horence/Elisabeth/intron_zscore/Arabidopsis/ref_files/Arabidopsis_genes_forReadZS.tsv"
gene_bed_path <- "/oak/stanford/groups/horence/rob/isoform_localizations/SRRS/inputs/kidney_liver_genes.bed"


## Function to get bin (genomic window) from position, strand, and chromsome
get_bin <- function(pos, binSize, chr, strand)
{
  pos <- as.numeric(pos)
  bin_num <- ceiling(pos/binSize)
  bin <- paste(chr, bin_num, strand, sep="_")
  return(bin)
}


## Function adapted from Rob Bierman to create bins from a bed file of genes (or UTRs, or other annotations)
get_bin_genes <- function(pos_list, binSize, chrom_list, strand, libraryType, bed_path)
{
  gene_locs <- fread(bed_path)
  bins <- vector("list", length(pos_list))
  for(i in 1:length(pos_list)){
    pos <- as.numeric(pos_list[i])
    chrom <- chrom_list[i]
    gene_name <- gene_locs[(chr == chrom) & (start <= pos) & (pos <= end), gene]
    if (length(gene_name) > 1) {  # pick first gene if there are several
       gene_name <- gene_name[[1]]
    }
    if (libraryType == "10X") {
       bins[[i]] <- paste(chrom, gene_name, strand, sep="_") # include strand in bin name for 10X
    } else if (libraryType == "SS2") {
       bins[[i]] <- paste(chrom, gene_name, sep="_") # don't include strand in bin name for SS2 since it is unstranded
    }
  }
  return(unlist(bins))
}



## Determine the strand of the data
get_strand <- function(strand_col)
{
  if (unique(strand_col) == "+")
  {
    strand_label <- "plus"
  } else if (unique(strand_col) == "-")
  {
    strand_label <- "minus"
  }
}

## Read in filter output
data <- fread(input_file, header = FALSE)
if (nrow(data) > 0) {  # if the input file is empty, don't do any of this.
  if (libType == '10X')
  {
    names(data) <- c('barcode', 'umi', 'strand','chr', 'pos', 'channel')

    # Get the strand label for the bin
    strand_label <- get_strand(data$strand)

    ## Deduplication step 1: deal with reads that have the same BC and UMI but different positions
    data[, numDiffPos := uniqueN(pos), by=c("barcode", "umi", "channel")]
    data[, pos := ifelse(numDiffPos > 1, mean(pos), pos), by=list(barcode, umi, channel)]
    # when there's more than one position for a BC + UMI pair, assigned position is average position

    ## Deduplication step 2: collapse reads with same BC, UMI, and position
    data <- unique(data[, list(chr, strand, pos, barcode, umi, channel)])

    ## Find total count of reads at each position, by channel and cell
    data <- data[, count := .N, by=.(pos, barcode, channel)]
    data <- data[,c("strand","chr","pos","barcode","count","channel")]
    data <- unique(data)

    ## Add column for cell id: paste channel and cell barcode
    data$cell_id <- paste(data$channel, data$barcode, sep = "_")
    data <- data[, c("cell_id", "chr", "pos", "strand", "count","channel")]

    ## Create bin from position
    if (geneVersion == T) {
       data <- data[, bin := get_bin_genes(pos, binSize, chr, strand_label, libType, gene_bed_path)] 
    } else {
       data <- data[, bin := get_bin(pos, binSize, chr, strand_label)]
    }

    ## Output
    output_file_name <- paste(basename, ".count", sep="")
    write.table(data, output_file_name, col.names=FALSE, row.names=FALSE, sep = "\t", quote=FALSE)

  } else if (libType == "SS2")
  {
    names(data) <- c('cell_id', 'strand', 'chr', 'pos', 'channel')

    # Get counts at each position
    data <- data[, count := .N, by=.(pos, cell_id, channel, strand)]
    data <- data[, c("cell_id", "chr", "pos", "strand", "count", "channel")]

     # Get the strand label for the bin
    strand_label <- get_strand(data$strand)

    ## Create bin from position
    if (geneVersion == T) {
       data <- data[, bin := get_bin_genes(pos, binSize, chr, strand_label, libType, gene_bed_path)] 
    } else {
       data <- data[, bin := get_bin(pos, binSize, chr, strand_label)]
    }

    ## Output
    output_file_name <- paste(basename, ".count", sep="")
    write.table(data, output_file_name, col.names=FALSE, row.names=FALSE, sep = "\t", quote=FALSE)
  }
}
