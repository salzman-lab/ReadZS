//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    main:
    // Param checks
    if (params.isSICILIAN) {
        if (params.isCellranger) {
            exit 1, "Invalid parameter input. SICILIAN output files should have `isCellranger = false`."
        }
    }
    if (params.libType == 'SS2') {
        if (params.isCellranger) {
            exit 1, "Invalid parameter input. SS2 data should have `isCellranger = false`."
        }
    }
    if (params.libType == '10X') {
        if (!params.isCellranger && !params.isSICILIAN) {
            exit 1, "Invalid parameter input. 10X data must either by cellranger or SICILIAN output."
        }
    }
    if (params.plot_only && params.skip_plot) {
        exit 1, "Invalid parameter input."
    }
    if (params.peaks_only && params.skip_peaks) {
        exit 1, "Invalid parameter input."
    }
    if (params.plot_only && params.skip_plot) {
        exit 1, "Invalid parameter input."
    }

}
