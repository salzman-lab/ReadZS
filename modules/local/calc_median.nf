process CALC_MEDIAN {
  tag "${basename}"

  label 'process_medium'

  publishDir "${params.outdir}/medians",
    pattern: "*medians*",
    mode: 'copy'
  publishDir "${params.outdir}/signif_pvalues",
    pattern: "*signifPvalues*",
        mode: 'copy'

  input:
  path zscore
  val ontologyCols
  val minCellsPerWindowOnt
  val minCtsPerCell
  val nPermutations

  output:
  path "${output_medians}"  , emit: medians
  path "${output_pvals}"    , emit: signif_medians

  script:
  basename = zscore.baseName
  output_medians = "${basename}_medians_${nPermutations}_permutations_min_${minCellsPerWindowOnt}_cellsPerGeneOnt_${minCtsPerCell}_ctsPerCell.txt"
  output_pvals = "${basename}_signif_medians_${nPermutations}_permutations_min_${minCellsPerWindowOnt}_cellsPerGeneOnt_${minCtsPerCell}_ctsPerCell.txt"
  """
  calc_median.R \\
    ${zscore} \\
    ${ontologyCols} \\
    ${minCellsPerWindowOnt} \\
    ${minCtsPerCell} \\
    ${nPermutations} \\
    ${output_medians} \\
    ${output_pvals}
  """
}
