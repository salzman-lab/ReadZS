include { SAMTOOLS_SORT           } from '../../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_INDEX          } from '../../modules/nf-core/modules/samtools/index/main'
include { PICARD_MARKDUPLICATES   } from '../../modules/nf-core/modules/picard/markduplicates/main'
include { FILTER_BAM_10X          } from '../../modules/local/filter_bam_10X'
include { FILTER_BAM_SS2          } from '../../modules/local/filter_bam_SS2'
include { MERGE_FILTERED          } from '../../modules/local/merge_filtered'

workflow PREPARE_SS2 {
    take:
    ch_input

    main:

    // Step 1: Remove duplicates
    PICARD_MARKDUPLICATES (
        ch_input,
        params.picard
    )

    SAMTOOLS_INDEX (
        PICARD_MARKDUPLICATES.out.bam_tuple
    )

    // Step 2: Filter bams
    FILTER_BAM_SS2 (
        SAMTOOLS_INDEX.out.bam_tuple,
        params.isSICILIAN,
        params.isCellranger,
        params.libType
    )

    // Step 3: Gather outputs and group by: "input"
    channel_merge_list = FILTER_BAM_SS2.out.filter
        .flatten()
        .collectFile { id, files ->
            [
                id,
                files.collect{ it.toString() }.join('\n') + '\n'
            ]
        }

    emit:
    channel_merge_list = channel_merge_list

}
