process PLOTTERPNG {
  publishDir "${params.outdir}/plots",
    mode: 'copy'

  input:
  path plotterFile
  val ontologyCols
  path gff

  output:
  path "*png"

  script:
  """
  make_plot.R \\
    ${plotterFile} \\
    ${ontologyCols} \\
    ${gff}
  """
}
