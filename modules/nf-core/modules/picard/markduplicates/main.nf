// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process PICARD_MARKDUPLICATES {
    tag "${bamFileID}"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode


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
    java -jar ${picard} MarkDuplicates -I ${bam} -O ${prefix}.bam -M ${bamFileID}.metrics.txt --QUIET true 
    """
}
