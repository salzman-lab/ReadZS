process ANNOTATE_WINDOWS {
  label 'process_medium'
  publishDir "${params.outdir}/annotated_files",
    mode: 'copy'

  conda 'bioconda::bedtools=2.30.0'
  input:
  val libType
  val isCellranger
  path chr_lengths
  path annotation_bed
  val binSize

  output:
  path "annotated_windows.file",   emit: annotated_windows

  script:
  if (params.libType == 'SS2')
    """
    bedtools makewindows -g ${chr_lengths} -w ${binSize} -i srcwinnum |
      awk -v OFS='\t' '{print \$0, ".", "+"}' |
      sort -k1,1 -k2,2n > windows.file
    bedtools intersect -a windows.file -b ${annotation_bed} -loj -wa |
      awk -v OFS='\t' '{print \$1,\$2,\$3,\$4,\$10}' |
      bedtools groupby -g 1,2,3,4 -c 5 -o collapse |
      sed '1i chr\tstart\tend\twindow\tgene' > annotated_windows.file
    """
  else if (params.libType == '10X')
    """
    bedtools makewindows -g ${chr_lengths} -w ${binSize} -i srcwinnum > unstranded_windows.file
    cat unstranded_windows.file | awk -v OFS='\t' '{print \$0, "plus", ".", "+"}' | 
      sed 's/\t/_/4' > pos_windows.file
    cat unstranded_windows.file | awk -v OFS='\t' '{print \$0, "minus", ".", "-"}' | 
      sed 's/\t/_/4' > minus_windows.file
    cat pos_windows.file minus_windows.file | sort -k1,1 -k2,2n > windows.file
    bedtools intersect -a windows.file -b ${annotation_bed} -loj -wa -s |
      awk -v OFS='\t' '{print \$1,\$2,\$3,\$4,\$6,\$10}' |
      bedtools groupby -g 1,2,3,4,5 -c 6 -o collapse |
      sed '1i chr\tstart\tend\twindow\tstrand\tgene' > annotated_windows.file
    """
  }
