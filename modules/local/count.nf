process COUNT {
  tag "${basename}"
  label 'process_medium'

  input:
  path filtered
  val libType
  val binSize

  output:
  path "*.count", optional: true, emit: count

  script:
  basename = filtered.baseName
  """
  count.R \\
    ${filtered} \\
    ${basename} \\
    ${libType} \\
    ${binSize}
  """
}
