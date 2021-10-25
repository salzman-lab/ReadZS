// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SAMTOOLS_SORT {
    tag "${bamFileID}"
    label 'process_medium'

    conda 'bioconda::samtools=1.13'
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/samtools:1.13--h8c37831_0"
    } else {
        container "quay.io/biocontainers/samtools:1.13--h8c37831_0"
    }

    input:
    tuple val(inputChannel), val(bamFileID), path(bam)

    output:
    tuple val(inputChannel), val(bamFileID), path("sorted*.bam")   , emit: bam
    path  "versions.yml"                                , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = "sorted.${bamFileID}"
    """
    samtools sort $options.args -@ $task.cpus -o ${prefix}.bam -T $prefix $bam
    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
