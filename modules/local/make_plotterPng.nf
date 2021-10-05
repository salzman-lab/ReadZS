process PLOTTERPNG {
  publishDir "${params.outdir}/plots",
    mode: 'copy'
  label 'process_low'

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
