// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process PICARD_MARKDUPLICATES {
    validExitStatus 0
    errorStrategy 'ignore'

    tag "${bamFileID}"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode
        
    conda (params.enable_conda ? "bioconda::picard=2.23.9" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/picard:2.23.9--0"
    } else {
        container "quay.io/biocontainers/picard:2.23.9--0"
    }

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
    def avail_mem = 3
    if (!task.memory) {
        log.info '[Picard MarkDuplicates] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    java -jar ${picard} MarkDuplicates -I ${bam} -O ${prefix}.bam -M ${bamFileID}.metrics.txt --QUIET true
    """
}
