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
        signif_windows.filter{ it.size()>0 },
        params.bin_size,
        params.ontology_cols,
        params.n_genes
    )

    // Step 2: Make plots
    MAKE_PNG (
        MAKE_PLOTTERFILE.out.plotterfiles.flatten(),
        params.ontology_cols
    )

}
