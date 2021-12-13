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
    rm -rf ${fasta}
    while read line
    do
        id="\$(echo "\${line}" | awk '{print \$1}')"
        file="\$(echo "\${line}" | awk '{print \$2}')"

        zcat "\${file}" | sed "s/>/>\${id}_/g" >> ${fasta}
    done < ${reference_samplesheet}
    """
}
