include { BOWTIE2_ALIGN } from  '../../../modules/nf-core/modules/bowtie2/align/main'
include { TRIMGALORE    } from  '../../../modules/nf-core/modules/trimgalore/main'

workflow ALIGN {
    take:

    main:
    if (params.reference) {
        index = file(params.reference)
    } else {
        MAKE_REF ()
        index = MAKE_REF.out.index
    }

    // Step 1: Parse fastq samplesheet
    ch_fastqs = Channel.fromPath(params.fastq_samplesheet)
        .splitCsv(header: false)
        .map { row ->
            tuple (
                row[0],
                file(row[1])
            )
        }

    // Step 2: Trim reads
    TRIMGALORE (
        ch_fastqs
    )

    // Step 3: Align reads
    BOWTIE2_ALIGN (
        TRIMGALORE.out.reads,
        index
    )

    emit:
    bam = BOWTIE2_ALIGN.out.bam
}
