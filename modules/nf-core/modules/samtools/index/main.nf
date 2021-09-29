// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SAMTOOLS_INDEX {
    tag "${bam}"
    label 'process_low'
    publishDir "${params.outdir}/bams",
        mode: params.publish_dir_mode

    conda (params.enable_conda ? 'bioconda::samtools=1.13' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/samtools:1.13--h8c37831_0"
    } else {
        container "quay.io/biocontainers/samtools:1.13--h8c37831_0"
    }

    input:
    tuple val(inputChannel), val(bamFileID), path(bam)

    output:
    tuple val(inputChannel), val(bamFileID), path(bam), path("*bai")     , emit: bam_tuple
    path  "versions.yml"                                            , emit: version

    script:
    def software = getSoftwareName(task.process)
    """
    samtools index $options.args $bam
    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
