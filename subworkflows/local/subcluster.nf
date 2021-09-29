include { FIND_PEAKS    } from  '../../modules/local/find_peaks'
include { MERGE         } from  '../../modules/local/merge'

workflow SUBCLUSTER {
    take:
    ch_counts
    ann_pvals

    main:
    counts_file_list = ch_counts
        .collectFile (name: 'all_counts.txt') { file ->
            file.toString() + '\n'
        }

    // Step 1: Merge all counts
    MERGE (
        counts_file_list,
        params.runName
    )

    // STEP 1: GMM Peak finding
    FIND_PEAKS (
        MERGE.out.merged,
        ann_pvals,
        params.peak_method,
        params.runName
    )

}
