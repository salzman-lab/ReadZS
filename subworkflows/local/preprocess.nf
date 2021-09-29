include { PREPARE_10X             } from './prepare_10X'
include { PREPARE_SS2             } from './prepare_SS2'
include { MERGE_FILTERED          } from '../../modules/local/merge_filtered'


workflow PREPROCESS {

    main:

    // Step 1: Create channel of chromosomes to analyze
    chrList = file(params.chr_lengths).readLines()
    ch_chrs = Channel.fromList(chrList)
        .map { it ->
            it.tokenize()[0]
        }

    // Step 2: Read in samplesheet
    if (params.useChannels) {
        ch_input = Channel.fromPath(params.input)
            .splitCsv(header: false)
            .map { row ->
                tuple(
                    row[0],
                    row[1],
                    file(row[2])
                )
            }
    } else {
        ch_input = Channel.fromPath(params.input)
            .splitCsv(header: false)
            .map { row ->
                tuple(
                    row[0],
                    row[0],
                    file(row[1])
                )
            }
    }

    // Step 3: Preprocess data with sorting and filtering
    if (params.libType == "10X") {
        PREPARE_10X (
            ch_input,
            ch_chrs
        )
        channel_merge_list = PREPARE_10X.out.channel_merge_list
    } else if (params.libType == "SS2") {
        PREPARE_SS2 (
            ch_input
        )
        channel_merge_list = PREPARE_SS2.out.channel_merge_list
    }

    // Step 4: Merge gruped files
    MERGE_FILTERED (
        channel_merge_list
    )

    emit:
    mergeFilter = MERGE_FILTERED.out.merged

}
