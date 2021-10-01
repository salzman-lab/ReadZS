include { SAMTOOLS_SORT           } from '../../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_INDEX          } from '../../modules/nf-core/modules/samtools/index/main'
include { PICARD_MARKDUPLICATES   } from '../../modules/nf-core/modules/picard/markduplicates/main'
include { FILTER_BAM_10X          } from '../../modules/local/filter_bam_10X'
include { FILTER_BAM_SS2          } from '../../modules/local/filter_bam_SS2'
include { MERGE_FILTERED          } from '../../modules/local/merge_filtered'
include { PICARD          } from '../../modules/local/picard'

workflow PREPARE_SS2 {
    take:
    ch_input

    main:

    // Step 1: Remove duplicates
    PICARD (
        ch_input,
        params.picard
    )

    SAMTOOLS_INDEX (
        PICARD.out.bam_tuple
    )

    // Step 2: Filter bams
    FILTER_BAM_SS2 (
        SAMTOOLS_INDEX.out.bam_tuple,
        params.isSICILIAN,
        params.isCellranger,
        params.libType
    )

    emit:
    filter = FILTER_BAM_SS2.out.filter

}
