process MERGE {
  tag "${basename}"

  publishDir "${params.outdir}/counts", mode: 'copy'

  input:
  path chr_merge_list
  val runName

  output:
  path "*.count", emit: merged

  script:
  basename = chr_merge_list.baseName
  outputFile = "${runName}_${basename}.count"
  """
  rm -f ${outputFile}
  cat ${chr_merge_list} |
    while read f; do
      cat \$f
    done >> ${outputFile}
  """
}
