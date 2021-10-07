include { COUNT         } from '../../modules/local/count'
include { MERGE         } from '../../modules/local/merge'
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


    // If 10X, merge files by chromosome
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
    } else if (params.libType == "SS2") {
        // If SS2, no need to merge.
        count_merge_list = COUNT.out.count
            .collectFile { file ->
                file.toString() + '\n'
            }
    }

    counts_resultsDir = "${launchDir}/${params.outdir}/counts"
    MERGE (
        count_merge_list,
        params.runName,
        true,
        counts_resultsDir,
        false
    )

    // Step 2: Calculate zscores
    CALC_ZSCORE (
        MERGE.out.merged,
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
    counts          = MERGE.out.merged
    pval_file_list  = pval_file_list
}
