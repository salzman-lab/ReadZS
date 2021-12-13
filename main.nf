#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/readzs
========================================================================================
    Github : https://github.com/nf-core/readzs
    Website: https://nf-co.re/readzs
    Slack  : https://nfcore.slack.com/channels/readzs
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    GENOME PARAMETER VALUES
========================================================================================
*/

//params.fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { READZS        } from './workflows/readzs'
include { READZS_DONOR  } from './workflows/readzs_donor'


//
// WORKFLOW: Run main nf-core/readzs analysis pipeline
//

workflow NFCORE_READZS_DONOR {
    READZS_DONOR ()
}


/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    NFCORE_READZS_DONOR ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
