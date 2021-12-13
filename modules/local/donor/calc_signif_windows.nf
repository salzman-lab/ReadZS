process CALC_SIGNIF_WINDOWS {
    tag "signif_window"

    label 'process_medium'

    publishDir "${params.outdir}",
    mode: 'copy'

    input:
    path zscores
    val ontology ontology_cols
    val min_cells_per_windowont
    val min_cts_per_cell
    val n_permutations
    val run_name
    val filter_mode
    val bin_size

    output:
    path "medians*"         , emit: medians
    path "signif_medians*"  , emit: signif_windows

    script:
    outfile="medians_${run_name}_plus_${filter_mode}_${binSize}_${min_cells_per_windowont}_minCellsPerWindowont_${min_cts_per_cell}_minCtsPerCell.txt"
    outfile_signif="signif_medians_${run_name}_plus_${filter_mode}_${min_cells_per_windowont}_minCellsPerWindowont_${min_cts_per_cell}_minCtsPerCell.txt"
    """
    calc_signif_windows.R \\
        ${zscores} \\
        ${ontology_cols} \\
        ${min_cells_per_windowont} \\
        ${min_cts_per_cell} \\
        ${n_permutations} \\
        ${outfile} \\
        ${outfile_signif}
    """
}
