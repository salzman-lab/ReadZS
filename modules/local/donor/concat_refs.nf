process CONCAT_REFS {
    tag "reference"

    label 'process_medium'

    publishDir "${params.outdir}/reference",
    mode: 'copy'

    input:
    path reference_samplesheet
    val reference_type
    val run_name


    output:
    path "${fasta}", emit: fasta

    script:
    fasta="reference_${reference_type}_${run_name}.fa"
    """
    concat_refs.sh \\
        ${reference_samplesheet} \\
        ${fasta}
    """
}
