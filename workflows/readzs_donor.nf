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
//include { INPUT_CHECK   } from '../subworkflows/local/donor/input_check'
include { MAKE_REF      } from '../subworkflows/local/donor/make_ref'
include { ALIGN         } from '../subworkflows/local/donor/align'
//include { CALCULATE     } from '../subworkflows/local/donor/calculate'
//include { PLOT          } from '../subworkflows/local/donor/plot'

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { BOWTIE2_ALIGN     } from '../modules/nf-core/modules/bowtie2/align/main'
include { BOWTIE2_BUILD     } from '../modules/nf-core/modules/bowtie2/build/main'
include { TRIMGALORE        } from '../modules/nf-core/modules/trimgalore/main'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow READZS_DONOR {

    //INPUT_CHECK ()

    // Generate reference, if needed
    if (params.reference) {
        index = file(params.reference)
    } else {
        MAKE_REF ()
        index = MAKE_REF.out.index.first()
    }

    // Align fastqs to reference
    ALIGN (
        index
    )
    ch_bams = ALIGN.out.bam

    // // Calculate zscores and significant windows
    // CALCULATE (
    //     ch_bams
    // )

    // // Plot significant windows
    // if (!params.skip_plot) {
    //     PLOT (
    //         CALCULATE.out.signif_medians
    //     )
    // }



}

/*
========================================================================================
    THE END
========================================================================================
*/
