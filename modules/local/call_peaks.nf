process CALL_PEAKS {
  publishDir "${params.outdir}/peaks",
    mode: 'copy'

  label 'process_medium'
  conda 'conda-forge::r-mclust=5.4.9'

  input:
  path all_counts
  path ann_pvals
  val peak_method
  val runName

  output:
  path "*.tsv", optional: true, emit: peaks

  script:
  output = "${runName}_peaks_${peak_method}.tsv"
  """
  GMM_based_peak_finder.R \\
    ${all_counts} \\
    ${ann_pvals} \\
    ${peak_method} \\
    ${output}
  """
}
