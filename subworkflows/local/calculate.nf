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
    counts_resultsDir = "${params.outdir}/counts"

    if (params.libType == "10X"){
        count_merge_list = COUNT.out.count
            .map { file ->
                def key = file.name.toString().tokenize('-')[1]
                return tuple(key, file)
            }
            .groupTuple()
            .collectFile (name: "counts.txt") { id, files ->
                [
                    id,
                    files.collect{ it.toString() }.join('\n') + '\n'
                ]
            }

        MERGE (
            count_merge_list,
            params.runName,
            true,
            counts_resultsDir,
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
            true,
            counts_resultsDir,
            false
        )
        ch_merged_counts = MERGE_SPLIT.out.merged
    }

    // Step 2: Calculate zscores
    CALC_ZSCORE (
        ch_merged_counts,
        params.zscores_only,
        params.metadata
    )

    // Step 3: Caclulate significant medians
    if (params.zscores_only) {
        pval_file_list = Channel.empty()
    } else {
        CALC_MEDIAN (
            CALC_ZSCORE.out.zscore,
            params.ontologyCols,
            params.minCellsPerWindowOnt,
            params.minCtsPerCell,
            params.nPermutations
        )
        // Collect to file
        pval_file_list = CALC_MEDIAN.out.signif_medians
            .collectFile{ file ->
                file.toString() + '\n'
            }
    }

    emit:
    counts          = ch_merged_counts
    pval_file_list  = pval_file_list
}
