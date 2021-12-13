include { BOWTIE2_ALIGN } from  '../../../modules/nf-core/modules/bowtie2/align/main'

workflow ALIGN {
    take:
    index

    main:
    // Step 1: Parse fastq sampelsheet
    ch_fastqs = Channel.fromPath(params.fastq_samplesheet)
        .splitCsv(header: false)
        .map { row ->
            tuple (
                row[0],
                file(row[1])
            )
        }

    // STEP 2: Align fastqs
    ALIGN (
        ch_fastqs,
        index
    )

    emit:
    bam = ALIGN.out.bam
}
