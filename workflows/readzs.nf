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
include { INPUT_CHECK       } from '../subworkflows/local/input_check'
include { SIGNIF_WINDOWS    } from '../subworkflows/local/signif_windows'
include { CALCULATE         } from '../subworkflows/local/calculate'
include { PLOT              } from '../subworkflows/local/plot'
include { PREPROCESS        } from '../subworkflows/local/preprocess'
include { PEAKS             } from '../subworkflows/local/peaks'

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

    INPUT_CHECK ()

    if (params.plot_only) {
        ch_all_pvals = Channel.fromPath(params.all_pvals_path)

        PLOT (
            ch_all_pvals,
            params.outdir
        )

    } else if (params.peaks_only) {
        // requires: counts_path, ann_pvals_path, runName, peakMethod
        ch_counts = Channel.fromPath(params.counts_path)
        ch_ann_pvals = Channel.fromPath(params.ann_pvals_path)

        PEAKS (
            ch_counts,
            ch_ann_pvals
        )

    } else {
        // Sort and filter reads
        PREPROCESS ()

        // Clculate zscores
        CALCULATE (
            PREPROCESS.out.filter
        )

        if (!params.zscores_only) {
            // Annotate windows file
            SIGNIF_WINDOWS (
                CALCULATE.out.zscores
            )

            // Channels for downstream analysis
            ch_counts = CALCULATE.out.counts
            ch_all_pvals = SIGNIF_WINDOWS.out.all_pvals
            ch_ann_pvals = SIGNIF_WINDOWS.out.ann_pvals


            // Plot
            if (!params.skip_plot) {
                PLOT (
                    ch_all_pvals,
                    params.outdir
                )
            }

            // Call peaks
            if (!params.skip_peaks) {
                PEAKS (
                    ch_counts,
                    ch_ann_pvals
                )
            }

        }
    }

}

/*
========================================================================================
    THE END
========================================================================================
*/
