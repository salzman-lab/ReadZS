process PVAL_LIST {
  publishDir "${params.outdir}/annotated_files",
    mode: 'copy'
  label 'process_low'

  input:
  path pval_file_list
  val runName
  path annotated_windows

  output:
  path "${runName}_all_pvals.txt",   emit: all_pvals,   optional: true
  path "${runName}_ann_pvals.txt",   emit: ann_pvals,   optional: true

  script:
  allPval_file = "${runName}_results.txt"
  outfile_allPvals = "${runName}_all_pvals.txt"
  outfile_annPvals = "${runName}_ann_pvals.txt"
  """
  [ -f "${allPval_file}" ] && rm "${allPval_file}"

  while read line
  do
    tail -n +2 \${line} >> ${allPval_file}
  done < ${pval_file_list}

  make_pval_list.R \\
    ${allPval_file} \\
    ${annotated_windows} \\
    ${outfile_allPvals} \\
    ${outfile_annPvals}
  """
}
