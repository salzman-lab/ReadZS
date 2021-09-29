process MERGE_FILTERED {
  tag "${basename}"

  input:
  path channel_merge_list

  output:
  path "*.mergeFilter", emit: merged

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
