process PLOTTERPNG {
  publishDir "${params.outdir}/plots",
    mode: 'copy'
  label 'process_low'
  container 'kaitlinchaung/readzs_small:v0.1'

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
