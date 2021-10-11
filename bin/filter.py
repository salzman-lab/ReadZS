#!/usr/bin/env python

import argparse
import pysam

def get_args():
  parser = argparse.ArgumentParser()
  parser.add_argument("--input_bam")
  parser.add_argument("--isSICILIAN")
  parser.add_argument("--libType")
  parser.add_argument("--bamName")
  parser.add_argument("--inputChannel")
  parser.add_argument("--chr", nargs='?')
  parser.add_argument("--isCellranger")
  args = parser.parse_args()
  return args

def pass_filter(read):
    cigar = read.cigar
    mq = read.mapping_quality
    read_length = read.query_length
    flag = read.flag
    if cigar == [(0, read_length)] and mq == 255 and flag in [0, 16, 1024, 1040]:  # 1024 and 1040 to allow reads marked as duplicates
        return True

def pass_filter_lenient(read):
    cigar = read.cigar
    mq = read.mapping_quality
    read_length = read.query_length
    flag = read.flag
    if cigar == [(0, read_length)] and mq == 255:  # 1024 and 1040 to allow reads marked as duplicates
        return True

def has_barcode_tags(read):
    if read.has_tag("CB") and read.has_tag("UB"):
        return True

def get_read_info(read, bam_file, isCellranger):
    chr = bam_file.get_reference_name(read.tid)
    if isCellranger:
        if "chr" not in chr:
            chr = "chr" + chr
    position = read.reference_start + 1
    if read.flag == 0:
            strand = "+"
    else:
        strand = "-"
    return chr, position, strand

def get_SICILIAN_outs(read):
    cbc = read.query_name.split("_")[1]
    umi = read.query_name.split("_")[2]
    return (cbc, umi)

def get_cellranger_outs(read):
    cbc = read.get_tag("CB").replace("-1", "")
    umi = read.get_tag("UB")
    return (cbc, umi)

def write_out_10X(cbc, umi, strand, chr, position, inputChannel, plus, minus):
    out = [cbc, umi, strand, chr, position, inputChannel]
    line = ' '.join(str(x) for x in out)
    if strand == "+":
        plus.write(line + '\n')
    else:
        minus.write(line + '\n')
    return None

def write_out_SS2(inputChannel, strand, chr, position, outfile):
    out = [inputChannel, strand, chr, position, inputChannel]
    line = ' '.join(str(x) for x in out)
    outfile.write(line + '\n')
    return None

def filter_10X(inputChannel, chrName, bamName, bam_file, isSICILIAN, isCellranger):
    outfile_plus = inputChannel + "-" + chrName + "-plus-" + bamName + ".filter"
    outfile_minus = inputChannel + "-" + chrName + "-minus-" + bamName + ".filter"
    plus = open(outfile_plus, "w")
    minus = open(outfile_minus, "w")

    for read in bam_file:
        if pass_filter(read):
            chr, position, strand = get_read_info(read, bam_file, isCellranger)
            if isSICILIAN:
                cbc, umi = get_SICILIAN_outs(read)
                write_out_10X(cbc, umi, strand, chr, position, inputChannel, plus, minus)
            else:
                if has_barcode_tags(read):
                    (cbc, umi) = get_cellranger_outs(read)
                    write_out_10X(cbc, umi, strand, chr, position, inputChannel, plus, minus)
    plus.close()
    minus.close()
    return None

def filter_SS2(inputChannel, bamName, bam_file, isCellranger):
    outfile = bamName + ".filter"
    out = open(outfile, "w")

    for read in bam_file:
        if pass_filter(read):
            chr, position, strand = get_read_info(read, bam_file, isCellranger)
            write_out_SS2(inputChannel, strand, chr, position, out)
    out.close()
    return None

def main():
    args = get_args()
    inputChannel = args.inputChannel
    libType = args.libType
    bamName = args.bamName

    if args.isSICILIAN.lower() == "true":
        isSICILIAN = True
    if args.isSICILIAN.lower() == "false":
        isSICILIAN = False

    if args.isCellranger.lower() == "true":
        isCellranger = True
    elif args.isCellranger.lower() == "false":
        isCellranger = False
    else:
        isCellranger = False

    bam_file = pysam.AlignmentFile(args.input_bam)

    if libType == "10X":
        if isCellranger:
            if "chr" not in args.chr:
                chrName = "chr" + args.chr
            else:
                chrName = args.chr
        else:
            chrName = args.chr
        filter_10X(inputChannel, chrName, bamName, bam_file, isSICILIAN, isCellranger)
    elif libType == "SS2":
        filter_SS2(inputChannel, bamName, bam_file, isCellranger)

main()

