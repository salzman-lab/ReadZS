include { SAMTOOLS_SORT           } from '../../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_INDEX          } from '../../modules/nf-core/modules/samtools/index/main'
include { PICARD_MARKDUPLICATES   } from '../../modules/nf-core/modules/picard/markduplicates/main'
include { FILTER_BAM_10X          } from '../../modules/local/filter_bam_10X'
include { FILTER_BAM_SS2          } from '../../modules/local/filter_bam_SS2'
include { MERGE_FILTERED          } from '../../modules/local/merge_filtered'

workflow PREPARE_10X {
    take:
    ch_input
    ch_chrs

    main:

    // Step 1: Sort and index BAM files
    if (!params.isCellranger) {
        SAMTOOLS_SORT (
            ch_input
        )
        ch_sorted = SAMTOOLS_SORT.out.bam
    } else {
        ch_sorted = ch_input
    }

    SAMTOOLS_INDEX (
        ch_sorted
    )

    // Step 2: Filter bams for each chr
    FILTER_BAM_10X (
        SAMTOOLS_INDEX.out.bam_tuple,
        params.isSICILIAN,
        params.isCellranger,
        params.libType,
        ch_chrs
    )

    // Step 3: Gather outputs and group by: "input.chr.strand"
    channel_merge_list = FILTER_BAM_10X.out.filter
        .flatten()
        .map { file ->
            key = file.name.toString().tokenize("-").subList(0, 3).join("-")
            return tuple(key, file)
        }
        .groupTuple()
        .collectFile { id, files ->
            [
                id,
                files.collect{ it.toString() }.join('\n') + '\n'
            ]
        }

    emit:
    channel_merge_list = channel_merge_list

}
