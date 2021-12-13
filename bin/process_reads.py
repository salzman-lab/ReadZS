#!/usr/bin/env python

import argparse
import math
import pysam
import pandas as pd


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bam")
    parser.add_argument("--filter_mode")
    parser.add_argument("--sample_ID")
    parser.add_argument("--bin_size", type=int)
    parser.add_argument("--outfile_plus")
    parser.add_argument("--outfile_minus")
    args = parser.parse_args()
    return args


def pass_filter(read, filter_mode):
    '''
    Returns true if read is not multimapping,
    conditional on the filter_mode
    '''
    # only keep reads that map to one position
    if filter_mode == 'stringent':
        if not read.has_tag('XS'):
            return True

    # 1. only keep reads that map to one position
    # 2. keep reads that map equally well to multiple places,
    # only if optimal score > suboptimal score
    elif filter_mode == 'lenient':
        if read.has_tag('XS'):
            if read.get_tag('AS') >= read.get_tag('XS'):
                return True
        else:
            return True


def filter_bam_file(bam_file, filter_mode):
    '''
    Takes a bam file and
    1. filters for uniquely mapping
    2. return positional dicts for plus and minus strands
    '''
    plus_dict = {}
    minus_dict = {}

    # Stream BAM file to filter and count reads
    for read in bam_file:
        # Check if each read is uniquely mapping, according to filter_mode
        if pass_filter(read, filter_mode):
            # Get pos_id 
            pos = read.reference_start + 1
            seqname = (
                bam_file
                .get_reference_name(read.tid)
                .replace('_', '-')
            )
            pos_id = f'{seqname}:{pos}'
            
            # Count reads in strand-specific manner
            pos_dict = minus_dict if read.is_reverse else plus_dict
            
            # Count reads at start position
            if pos_id not in pos_dict.keys():
                pos_dict[pos_id] = 1
            else:
                pos_dict[pos_id] += 1

    return plus_dict, minus_dict


def get_position_bin(pos, seqname, strand, bin_size):
    '''
    Function to assign bins to positions, in accordiance to bin_size
    Outputs: seqname_strand_binNum
    '''
    bin_num = math.ceil(pos / bin_size)
    bin_name = f'{seqname}_{strand}_{bin_num}'
    return bin_name


def make_counts_file(pos_dict, strand, bin_size, sample_ID):
    '''
    Takes a dict of { pos: {seqname: count} }
    and returns a df with binned start positions
    '''
    df = (
        pd.DataFrame.from_dict(
            pos_dict, 
            orient='index'
        )
        .reset_index()
    )
    df.columns = ['pos_id', 'count']
    
    # split up column 
    df[['seqname', 'pos']] = df['pos_id'].str.split(':', 1, expand=True)
    df = df[['seqname', 'pos', 'count']]

    # add cols
    df['sample_ID'] = sample_ID

    # assign positions to bins
    df['window'] = (
        df.apply(
            lambda x:
            get_position_bin(int(x.pos), x.seqname, strand, bin_size),
            axis=1
        )
    )

    # sort output
    df.sort_values(
        ['seqname', 'pos', 'window'],
        inplace=True
    )

    return df


def main():

    args = get_args()

    save = pysam.set_verbosity(0)
    bam_file = pysam.AlignmentFile(args.bam)

    # Get position counts for plus and minus strand
    plus_dict, minus_dict = filter_bam_file(bam_file, args.filter_mode)
    
    # Make counts df for plus and minus
    plus_df = make_counts_file(plus_dict, 'plus', args.bin_size, args.sample_ID)
    minus_df = make_counts_file(minus_dict, 'minus', args.bin_size, args.sample_ID)
    
    # write out
    plus_df.to_csv(args.outfile_plus, index=False, sep='\t')
    minus_df.to_csv(args.outfile_minus, index=False,sep='\t')


main()
