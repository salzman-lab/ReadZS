/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
//WorkflowReadzs.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
//def checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
//for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
//if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }


/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

//
// MODULE: Local to the pipeline
//
include { GET_SOFTWARE_VERSIONS } from '../modules/local/get_software_versions' addParams( options: [publish_files : ['tsv':'']] )

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { SIGNIF_WINDOWS      } from '../subworkflows/local/signif_windows'
include { CALCULATE     } from '../subworkflows/local/calculate'
include { PLOT          } from '../subworkflows/local/plot'
include { PREPROCESS    } from '../subworkflows/local/preprocess'
include { SUBCLUSTER    } from '../subworkflows/local/subcluster'

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { PICARD_MARKDUPLICATES     } from '../modules/nf-core/modules/picard/markduplicates/main'
include { SAMTOOLS_SORT             } from '../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_INDEX            } from '../modules/nf-core/modules/samtools/index/main'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow READZS {

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
    if (params.subcluster_only && params.skip_subcluster) {
        exit 1, "Invalid parameter input."
    }
    if (params.plot_only && params.skip_plot) {
        exit 1, "Invalid parameter input."
    }

    PREPROCESS ()

    CALCULATE (
        PREPROCESS.out.filter
    )

    if (!params.zscores_only) {
        // Gather significant pvalues
        if (params.plot_only) {
            ch_all_pvals = Channel.fromPath(params.all_pvals_path)
        } else if (params.subcluster_only) {
            ch_counts = Channel.fromPath(params.counts_path)
            ch_ann_pvals = Channel.fromPath(params.ann_pvals_path)
        } else {
            // Annotate windows file
            SIGNIF_WINDOWS (
                CALCULATE.out.zscores
            )

            // Init channels for downstream analysis
            ch_counts = CALCULATE.out.counts
            ch_all_pvals = SIGNIF_WINDOWS.out.all_pvals
            ch_ann_pvals = SIGNIF_WINDOWS.out.ann_pvals
        }

        // Plot
        if (!params.skip_plot || params.plot_only) {
            resultsDir = "${launchDir}/${params.outdir}"
            PLOT (
                ch_all_pvals,
                resultsDir
            )
        }

        // Subcluster
        if (!params.skip_subcluster || params.subcluster_only) {
            SUBCLUSTER (
                ch_counts,
                ch_ann_pvals
            )
        }

    }

}

/*
========================================================================================
    THE END
========================================================================================
*/
