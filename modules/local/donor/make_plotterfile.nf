process MAKE_PLOTTERFILE {
    tag "plotterfile"

    label 'process_medium'

    input:
    path counts
    path zscores
    path significant_windows
    val bin_size
    val ont_cols
    val n_genes

    output:
    path "*.txt"   , emit: plotterfiles

    script:
    """
    make_plotterfile_donor.R \\
        ${significant_windows} \\
        ${counts} \\
        ${zscores} \\
        ${bin_size} \\
        ${ont_cols} \\
        ${n_genes}
    """
}
