include { CALL_PEAKS    } from  '../../modules/local/call_peaks'
include { MERGE         } from  '../../modules/local/merge'

workflow PEAKS {
    take:
    ch_counts
    ann_pvals

    main:

    counts_file_list = ch_counts
    .collectFile (name: 'all_counts.txt') { file ->
        file.toString() + '\n'
    }

    resultsDir = "${params.outdir}/counts"
    MERGE (
        counts_file_list,
        params.runName,
        true,
        resultsDir,
        false
    )
    ch_counts = MERGE.out.merged


    // STEP 1: GMM Peak finding
    CALL_PEAKS (
        ch_counts,
        ann_pvals,
        params.peak_method,
        params.runName
    )

}
