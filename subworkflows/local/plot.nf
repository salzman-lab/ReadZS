include { PLOTTERFILE   } from  '../../modules/local/make_plotterFile'
include { PLOTTERPNG    } from  '../../modules/local/make_plotterPng'

workflow PLOT {
    take:
    all_pvals
    resultsDir

    main:
    // STEP 1: Generate plotter files
    PLOTTERFILE (
        all_pvals,
        params.binSize,
        params.ontologyCols,
        params.numPlots,
        params.runName,
        resultsDir
    )

    // STEP 2: Plot
    PLOTTERPNG (
        PLOTTERFILE.out.flatten(),
        params.ontologyCols,
        params.gff
    )

}
