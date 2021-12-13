process CALC_ZSCORE {
    tag "zscore"

    label 'process_medium'

    publishDir "${params.outdir}",
    mode: 'copy'

    input:
    path counts
    path metadata
    val run_name
    val filter_mode
    val bin_size

    output:
    path "*.txt", emit: zscores

    script:
    outfile="zscores_${run_name}_plus_${filter_mode}_${binSize}.txt"
    """
    calc_zscore_donor.R \\
        ${counts} \\
        ${outfile} \\
        ${metadata}
    """
}
