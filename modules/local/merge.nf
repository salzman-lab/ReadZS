process MERGE {
  tag "${basename}"
  label 'process_low'

  publishDir "${publishDir}", mode: 'copy'

  input:
  path chr_merge_list
  val runName
  path publishDir

  output:
  path "*.txt", emit: merged

  script:
  basename = chr_merge_list.baseName
  outputFile = "${runName}_${basename}.txt"
  """
  rm -f ${outputFile}
  cat ${chr_merge_list} |
    while read f; do
      cat \$f
    done >> ${outputFile}
  """
}
