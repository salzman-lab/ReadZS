process PVAL_LIST {
  publishDir "${params.outdir}/annotated_files",
    mode: 'copy'
  label 'process_low'

  input:
  path allPval_file
  val runName
  path annotated_windows

  output:
  path "${runName}_all_pvals.txt",   emit: all_pvals,   optional: true
  path "${runName}_ann_pvals.txt",   emit: ann_pvals,   optional: true

  script:
  outfile_allPvals = "${runName}_all_pvals.txt"
  outfile_annPvals = "${runName}_ann_pvals.txt"
  """
  make_pval_list.R \\
    ${allPval_file} \\
    ${annotated_windows} \\
    ${outfile_allPvals} \\
    ${outfile_annPvals}
  """
}
