#!/usr/bin/env Rscript

if (!require("data.table")) {
  install.packages("data.table", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(data.table)
}
if (!require("mclust")) {
  install.packages("mclust", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(mclust)
}

if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("SamSPECTRAL")
library(SamSPECTRAL)

if (!require("inflection")) {
  install.packages("inflection", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(inflection)
}
if (!require("R.utils")) {
  install.packages("R.utils", dependencies = TRUE, repos = "http://cran.us.r-project.org")
  library(R.utils)
}

args = commandArgs(trailingOnly = TRUE)
position_count_file <- args[1]
ann_pvals <- args[2]
method <- args[3]  # either knee or max
output <- args[4]

position_count <- fread(position_count_file, header=F)
names(position_count) = c("cell_id", "chr", "pos", "strand", "count", "channel", "window")

all_windows <- fread(ann_pvals, header=T)
significant_windows <- all_windows[, c("window")]
significant_windows <- significant_windows[!duplicated(significant_windows),]

num_peaks = c()
peak_pos = c()
ICL_vec = c()
window_of_interest = c()
comp_prob = c()
for (counter in 1:nrow(significant_windows)){
  print(counter)
  tryCatch({
    window_of_interest[counter] = significant_windows$window[counter]
    position_count_gene = position_count[window == window_of_interest[counter]]
    positions_df = data.frame(rep(position_count_gene$pos, position_count_gene$count))
    names(positions_df) = "N"
    withTimeout(   ICL <- mclustICL(positions_df),timeout = 300)

    ICL_vector = ICL[,2]
    ICL_vector = ICL_vector[!is.na(ICL_vector)]
    if (method == "max"){
      num_peaks[counter] = as.integer(unique(names(which(ICL_vector == max(ICL_vector, na.rm = TRUE)))))
    } else if (method == "knee"){
      knee_points_ICL = kneepointDetection(ICL_vector)  # I will select the knee points for the BIC criterion
      num_peaks[counter] = knee_points_ICL$MinIndex
      if(length(ICL_vector)>5){
        num_peaks[counter] =  d2uik(as.numeric(names(ICL_vector)),ICL_vector)
      }
    }
    GMM_model = Mclust(positions_df,G = num_peaks[counter])
    peak_pos[counter] = paste(as.integer(GMM_model$parameters$mean),collapse=",")
    comp_prob[counter] = paste(as.character(round(GMM_model$parameters$pro,3)),collapse=",")
    ICL_vec[counter] = paste(as.integer(ICL_vector),collapse=",")
  },error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
}
final_dt = data.table(window = window_of_interest,num_peaks,peak_pos,comp_prob,ICL_vec)
write.table(final_dt, output, row.names=FALSE, quote=FALSE, sep="\t")

