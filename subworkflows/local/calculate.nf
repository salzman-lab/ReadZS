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
        chr_merge_list = COUNT.out.count
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
            chr_merge_list,
            params.runName
        )
        ch_counts = MERGE.out.merged
    }

    // If SS2, no need to merge.
    if (params.libType == "SS2") {
        ch_counts = COUNT.out.count
    }

    // Step 2: Calculate zscores
    CALC_ZSCORE (
        ch_counts,
        params.zscores_only,
        params.metadata
    )

    if (params.libType == "SS2") {
        zscores_file_list = CALC_ZSCORE.out.zscore
            .collectFile { file ->
                file.toString() + '\n'
            }
        // If smartseq2, merge all the counts files together before zscore calc.
        resultsDir = "${params.outdir}/zscore"
        MERGE (
            zscores_file_list,
            params.runName,
            "${resultsDir}"
        )
        ch_zscore = MERGE.out.merged
    } else {
        ch_zscore = CALC_ZSCORE.out.zscore
    }

    // Step 3: Caclulate significant medians
    if (params.zscores_only) {
        pval_file_list = Channel.empty()
    } else {
        CALC_MEDIAN (
            ch_zscore,
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
    counts          = ch_counts
    pval_file_list  = pval_file_list
}
