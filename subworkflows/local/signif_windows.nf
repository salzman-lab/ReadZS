include { ANNOTATE_WINDOWS  } from  '../../modules/local/annotate_windows'
include { PVAL_LIST     } from  '../../modules/local/make_pval_list'
include { MERGE         } from '../../modules/local/merge'
include { MERGE_SPLIT   } from '../../modules/local/merge_split'
include { CALC_ZSCORE   } from '../../modules/local/calc_zscore'
include { CALC_MEDIAN   } from '../../modules/local/calc_median'

workflow SIGNIF_WINDOWS {
    take:
    ch_zcores

    main:

    // Step 1: Calculate medians
    CALC_MEDIAN (
        ch_zcores,
        params.ontologyCols,
        params.minCellsPerWindowOnt,
        params.minCtsPerCell,
        params.nPermutations
    )

    // Step 2: Collect to file
    pval_file_list = CALC_MEDIAN.out.signif_medians
        .collectFile (name: 'all_signif_medians.txt') { file ->
            file.toString() + '\n'
        }
    pvals_resultsDir = "${params.outdir}/results/signif_medians"
    MERGE (
        pval_file_list,
        params.runName,
        true,
        pvals_resultsDir,
        true
    )

    // Step 3: Annotate windows
    ANNOTATE_WINDOWS (
        params.isCellranger,
        params.chr_lengths,
        params.annotation_bed,
        params.binSize
    )

    // Step 4: Create annotated and unannotated signif window lists
    PVAL_LIST (
        MERGE.out.merged,
        params.runName,
        ANNOTATE_WINDOWS.out.annotated_windows
    )

    emit:
    ann_pvals = PVAL_LIST.out.ann_pvals
    all_pvals = PVAL_LIST.out.all_pvals
}
