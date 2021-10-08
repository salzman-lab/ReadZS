process MERGE_SPLIT {
  tag "${basename}"
  label 'process_low'

  publishDir "${params.outdir}/${subDir}",
    mode: 'copy'

  input:
  path chr_merge_list
  val runName
  val subDir
  val removeHeader

  output:
  path "*.count", emit: merged

  script:
  basename = chr_merge_list.baseName
  outputFile = "${runName}_${basename}.txt"
  """
  rm -f ${outputFile}
  cat ${chr_merge_list} |
      while read f; do
      awk -v var=${runName} '{if(\$2 ~ /chr/) print >> var"_"\$2".count"}' \$f
      done
  """
}
