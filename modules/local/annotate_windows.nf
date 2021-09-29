process ANNOTATE_WINDOWS {
  conda 'bedtools'

  publishDir "${params.outdir}",
    mode: 'copy'

  input:
  val isCellranger
  path chr_lengths
  path annotation_bed
  val binSize

  output:
  path "annotated_windows.file",   emit: annotated_windows

  script:
  if (isCellranger)
    """
    bedtools makewindows -g ${chr_lengths} -w ${binSize} -i srcwinnum |
      awk -v OFS='\t' '{print "chr"\$1,\$2,\$3,"chr"\$4, ".", "+"}' |
      sort -k1,1 -k2,2n > windows.file
    bedtools intersect -a windows.file -b ${annotation_bed} -loj -wa |
      awk -v OFS='\t' '{print \$1,\$2,\$3,\$4,\$10}' |
      sed '1i chr\tstart\tend\tchr_window\tgene' > annotated_windows.file
    """
  else
    """
    bedtools makewindows -g ${chr_lengths} -w ${binSize} -i srcwinnum |
      awk -v OFS='\t' '{print \$0, ".", "+"}' |
      sort -k1,1 -k2,2n > windows.file
    bedtools intersect -a windows.file -b ${annotation_bed} -loj -wa |
      awk -v OFS='\t' '{print \$1,\$2,\$3,\$4,\$10}' |
      sed '1i chr\tstart\tend\tchr_window\tgene' > annotated_windows.file
    """
}
