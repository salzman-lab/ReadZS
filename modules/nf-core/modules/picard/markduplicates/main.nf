// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process PICARD_MARKDUPLICATES {
    tag "${bamFileID}"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode

    conda (params.enable_conda ? "bioconda::picard=2.27.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:2.27.1--hdfd78af_0' :
        'quay.io/biocontainers/picard:2.27.1--hdfd78af_0' }"

    input:
    tuple val(inputChannel), val(bamFileID), path(bam)
    path picard

    output:
    tuple val(inputChannel), val(bamFileID), path("dedup*bam")          , emit: bam_tuple
    path "*.metrics.txt"                                                , emit: metrics
    path  "*.version.txt"                                               , emit: version
    
    script:
    def software  = getSoftwareName(task.process)
    def prefix    = "dedup.${bamFileID}"
    """
    picard MarkDuplicates -I ${bam} -O ${prefix}.bam -M ${bamFileID}.metrics.txt --QUIET true 
    """
}
