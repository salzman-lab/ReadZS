process CALC_ZSCORE {
  tag "${basename}"
  publishDir "${params.outdir}/zscore",
    mode: 'copy'
  label 'process_high'

  input:
  path count
  val zscores_only
  path metadata

  output:
  path "*.zscore", emit: zscore

  script:
  basename = count.baseName
  outputFile = "${basename}.zscore"
  """
  calc_zscore.R \\
    ${count} \\
    ${outputFile} \\
    ${metadata} \\
    ${zscores_only}
  """
}
