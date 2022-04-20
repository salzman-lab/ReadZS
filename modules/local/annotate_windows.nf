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
    if (isCellranger)
      """
      bedtools makewindows -g ${chr_lengths} -w ${binSize} -i srcwinnum |
        awk -v OFS='\t' '{print \$1,\$2,\$3,\$4, ".", "+"}' |
        sort -k1,1 -k2,2n > windows.file
      bedtools intersect -a windows.file -b ${annotation_bed} -loj -wa |
        awk -v OFS='\t' '{print \$1,\$2,\$3,\$4,\$10}' |
        bedtools groupby -g 1,2,3,4 -c 5 -o collapse |
        sed '1i chr\tstart\tend\tchr_window\tgene' > annotated_windows.file
      """
    else
      """
      bedtools makewindows -g ${chr_lengths} -w ${binSize} -i srcwinnum |
        awk -v OFS='\t' '{print \$0, ".", "+"}' |
        sort -k1,1 -k2,2n > windows.file
      bedtools intersect -a windows.file -b ${annotation_bed} -loj -wa |
        awk -v OFS='\t' '{print \$1,\$2,\$3,\$4,\$10}' |
        bedtools groupby -g 1,2,3,4 -c 5 -o collapse |
        sed '1i chr\tstart\tend\tchr_window\tgene' > annotated_windows.file
      """
  else if (params.libType == '10X')
    if (isCellranger)
      """
      bedtools makewindows -g ${chr_lengths} -w ${binSize} -i srcwinnum |
        awk -v OFS='\t' '{print \$1,\$2,\$3,\$4, ".", "+"}' |
        sort -k1,1 -k2,2n > windows.file
      bedtools intersect -a windows.file -b ${annotation_bed} -loj -wa -s |
        awk -v OFS='\t' '{print \$1,\$2,\$3,\$4,\$10}' |
        bedtools groupby -g 1,2,3,4 -c 5 -o collapse |
        sed '1i chr\tstart\tend\tchr_window\tgene' > annotated_windows.file
      """
    else
      """
      bedtools makewindows -g ${chr_lengths} -w ${binSize} -i srcwinnum |
        awk -v OFS='\t' '{print \$0, ".", "+"}' |
        sort -k1,1 -k2,2n > windows.file
      bedtools intersect -a windows.file -b ${annotation_bed} -loj -wa -s |
        awk -v OFS='\t' '{print \$1,\$2,\$3,\$4,\$10}' |
        bedtools groupby -g 1,2,3,4 -c 5 -o collapse |
        sed '1i chr\tstart\tend\tchr_window\tgene' > annotated_windows.file
      """
}
