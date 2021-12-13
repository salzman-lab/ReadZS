#!/bin/bash
## script to create a master reference by concatenating smaller reference files and
## adding reference sources to the contig/chhromosomal; ids
reference_samplesheet=$1
fasta=$2

rm -rf ${fasta}
while read line
do
    id=$(echo ${line} | awk '{print $1}')
    file=$(echo ${line} | awk '{print $2}')
    ext="${file##*.}"

    if [[ "${ext}" == "gz" ]]
    then
        zcat ${file} | sed "s/>/>${id}_/g" >> ${fasta}
    else
        sed "s/>/>${id}_/g" ${file} >> ${fasta}
    fi
done < ${reference_samplesheet}
