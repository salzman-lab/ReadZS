
process PLOTTERFILE {
  publishDir "${params.outdir}/plotter_files",
    mode: 'copy'

  input:
  path all_pvals
  val binSize
  val ontologyCols
  val numPlots
  val runName
  val outdir

  output:
  path "*.plotterFile"

  script:
  """
  make_plotter_files.R \\
    ${all_pvals} \\
    ${binSize} \\
    ${ontologyCols} \\
    ${numPlots} \\
    ${outdir} \\
    ${runName}
  """
}
