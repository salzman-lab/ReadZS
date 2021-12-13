process TRIMGALORE {
    tag "id"
    label 'process_high'

    conda (params.enable_conda ? 'bioconda::trim-galore=0.6.7' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trim-galore:0.6.7--hdfd78af_0' :
        'quay.io/biocontainers/trim-galore:0.6.7--hdfd78af_0' }"

    input:
    tuple val(id), path(reads)

    output:
    tuple val(id), path("*.fq.gz")  , emit: reads
    path "*report.txt"              , emit: log
    path "versions.yml"             , emit: versions

    path "*.html"                   , emit: html optional true
    path "*.zip"                    , emit: zip optional true

    script:
    def args = task.ext.args ?: ''
    // Calculate number of --cores for TrimGalore based on value of task.cpus
    // See: https://github.com/FelixKrueger/TrimGalore/blob/master/Changelog.md#version-060-release-on-1-mar-2019
    // See: https://github.com/nf-core/atacseq/pull/65
    def cores = 1
    if (task.cpus) {
        cores = (task.cpus as int) - 4
        if (meta.single_end) cores = (task.cpus as int) - 3
        if (cores < 1) cores = 1
        if (cores > 4) cores = 4
    }
    """
    [ ! -f  ${id}.fastq.gz ] && ln -s $reads ${prefiidx}.fastq.gz
    trim_galore \\
        --cores $cores \\
        --gzip \\
        ${id}.fastq.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimgalore: \$(echo \$(trim_galore --version 2>&1) | sed 's/^.*version //; s/Last.*\$//')
        cutadapt: \$(cutadapt --version)
    END_VERSIONS
    """
    
}
