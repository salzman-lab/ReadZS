include { PROCESS_READS         } from  '../../../modules/local/donor/process_reads'
include { CALC_ZSCORE           } from  '../../../modules/local/donor/calc_zscore'
include { CALC_SIGNIF_WINDOWS   } from  '../../../modules/local/donor/calc_signif_windows'


workflow CALCULATE {
    take:
    ch_bams

    main:
    // Step 1: Filter reads, count positions, and assign bins to positions
    PROCESS_READS (
        ch_bams,
        params.filter_mode,
        params.bin_size
    )

    // Step 2: Merge into one file
    counts_file = "counts_${params.run_name}_${params.filter_mode}_${params.binSize}.txt"

    PROCESS_READS.out.counts
        .collectFile(
            name:       "${counts_file}",
            storeDir:   "${params.outdir}"
        ) { file ->
            file.collect{ it.text }.join('\n') + '\n'
        }
        .set{ ch_counts }

    // Step 2: Calculate zscores
    CALC_ZSCORE (
        ch_counts,
        params.metadata,
        params.run_name,
        params.filter_mode,
        params.bin_size
    )

    // Step 3: Calculate significant windows
    CALC_SIGNIF_WINDOWS (
        CALC_ZSCORE.out.zscores,
        params.ontology_cols,
        params.min_cells_per_windowont,
        params.min_cts_per_cell,
        params.n_permutations,
        params.run_name,
        params.filter_mode,
        params.bin_size
    )

    emit:
    counts          = ch_counts
    zscores         = CALC_ZSCORE.out.zscores
    signif_windows  = CALC_SIGNIF_WINDOWS.out.signif_windows
}
