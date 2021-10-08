include { COUNT         } from '../../modules/local/count'
include { MERGE         } from '../../modules/local/merge'
include { MERGE_SPLIT   } from '../../modules/local/merge_split'
include { CALC_ZSCORE   } from '../../modules/local/calc_zscore'
include { CALC_MEDIAN   } from '../../modules/local/calc_median'

workflow CALCULATE {
    take:
    ch_mergeFilter

    main:
    // Step 1: Calculate counts for each filtered file
    COUNT (
        ch_mergeFilter,
        params.libType,
        params.binSize
    )

    // Step 2: Merge by Chromosome and output
    if (params.libType == "10X"){
        count_merge_list = COUNT.out.count
            .map { file ->
                def key = file.name.toString().tokenize('-')[1]
                return tuple(key, file)
            }
            .groupTuple()
            .collectFile (name: 'all_counts.txt') { id, files ->
                [
                    id,
                    files.collect{ it.toString() }.join('\n') + '\n'
                ]
            }

        MERGE (
            count_merge_list,
            params.runName,
            "counts",
            false
        )
        ch_merged_counts = MERGE.out.merged
    } else if (params.libType == "SS2") {
        // If SS2, no need to merge.
        count_merge_list = COUNT.out.count
            .collectFile (name: 'all_counts.txt') { file ->
                file.toString() + '\n'
            }
        MERGE_SPLIT (
            count_merge_list,
            params.runName,
            "counts",
            false
        )
        ch_merged_counts = MERGE_SPLIT.out.merged.flatten()
    }

    // Step 2: Calculate zscores
    CALC_ZSCORE (
        ch_merged_counts,
        params.zscores_only,
        params.metadata
    )

    emit:
    counts          = ch_merged_counts
    zscores         = CALC_ZSCORE.out.zscore
}
