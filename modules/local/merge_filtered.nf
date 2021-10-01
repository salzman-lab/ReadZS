process MERGE_FILTERED {
  tag "${basename}"
  label 'process_low'
  input:
  path channel_merge_list

  output:
  path "*.mergeFilter", emit: filter

  script:
  basename = channel_merge_list.baseName
  outputFile = "${basename}.mergeFilter"
  """
  rm -f ${outputFile}
  cat ${channel_merge_list} |
    while read f; do
      cat \$f
    done >> ${outputFile}
  """
}
