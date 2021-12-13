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
    path "${ref_file}"  , emit: fasta

    script:
    ref_file="reference_${reference_type}_${run_name}.fa"
    """
    rm -rf ${ref_file}
    while read line
    do
        id=$(echo \${line} | awk '{print \$1}')
        file=$(echo \${line} | awk '{print \$2}')
        ext="\${file##*.}"

        if [[ "\${ext}" == "gz" ]]
        then
            zcat \${file} | sed "s/>/>\${id}_/g" >> ${ref_file}
        else
            sed "s/>/>\${id}_/g" \${file} >> ${ref_file}
        fi
    done < ${reference_samplesheet}
    """
}
