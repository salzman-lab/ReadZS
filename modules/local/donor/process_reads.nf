process PROCESS_READS {
    tag "process_reads"

    label 'process_medium'

    publishDir "${params.outdir}",
    mode: 'copy'

    input:
    tuple val(id), path(bam)
    val filter_mode
    val bin_size

    output:
    path "*.txt"   , emit: counts

    script:
    outfile_plus="counts_${id}_plus_${filter_mode}_${bin_size}.txt"
    outfile_minus="counts_${id}_minus_${filter_mode}_${bin_size}.txt"
    """
    process_reads.py \\
        --bam ${bam} \\
        --filter_mode ${filter_mode} \\
        --sample_ID ${id} \\
        --bin_size ${bin_size} \\
        --outfile_plus ${outfile_plus} \\
        --outfile_minus ${outfile_minus}
    """
}
