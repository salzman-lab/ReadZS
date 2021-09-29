process FILTER_BAM_SS2 {
  tag "${bamFileID}"

  input:
  tuple val(inputChannel), val(bamFileID), path(bam), path(bai)
  val isSICILIAN
  val isCellranger
  val libType

  output:
  path "*.filter", emit: filter

  script:
  """
  filter.py \\
    --input_bam <(samtools view -b ${bam} ${chr} ) \\
    --isSICILIAN ${isSICILIAN} \\
    --isCellranger ${isCellranger} \\
    --libType ${libType} \\
    --bamName ${bamFileID} \\
    --inputChannel ${inputChannel}
  """
}
