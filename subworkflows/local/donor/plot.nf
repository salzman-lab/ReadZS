include { MAKE_PLOTTERFILE  } from  '../../../modules/local/donor/make_plotterfile'
include { MAKE_PNG          } from  '../../../modules/local/donor/make_png'

workflow PLOT {
    take:
    counts
    zscores
    signif_windows

    main:
    // Step 1: Make plotterfiles
    MAKE_PLOTTERFILE (
        counts,
        zscores,
        signif_windows,
        params.bin_size,
        params.ont_cols,
        params.n_genes
    )

    // Step 2: Make plots
    MAKE_PNG (
        MAKE_PLOTTERFILE.out.plotterfiles.flatten(),
        params.ont_cols
    )

    emit:

}
