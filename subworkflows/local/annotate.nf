include { ANNOTATE_WINDOWS  } from  '../../modules/local/annotate_windows'
include { PVAL_LIST     } from  '../../modules/local/make_pval_list'

workflow ANNOTATE {
    take:
    pval_file_list

    main:
    // Step 1: Annotate windows with genes file
    ANNOTATE_WINDOWS (
        params.isCellranger,
        params.chr_lengths,
        params.annotation_bed,
        params.binSize
    )

    // Step 2: Gather significant windows
    PVAL_LIST (
        pval_file_list,
        params.runName,
        ANNOTATE_WINDOWS.out.annotated_windows
    )

    emit:
    ann_pvals = PVAL_LIST.out.ann_pvals
    all_pvals = PVAL_LIST.out.all_pvals
}
