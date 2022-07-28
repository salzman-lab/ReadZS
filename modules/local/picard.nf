process PICARD {
    tag "${bamName}"
    label 'process_medium'

    conda (params.enable_conda ? 'bioconda::picard=2.26.2' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:2.27.1--hdfd78af_0' :
        'quay.io/biocontainers/picard:2.27.1--hdfd78af_0' }"

    input:
    tuple val(inputChannel), val(bamFileID), path(bam)

    output:
    tuple val(inputChannel), val(bamFileID), path("*dedup*"), emit: bam_tuple

    script:
    outputFile = "${bamFileID}.dedup"
    metrics = "${bamFileID}.metrics"
    """
    picard MarkDuplicates -I ${bam} -O ${outputFile} -M ${metrics} --QUIET true
    """
}
