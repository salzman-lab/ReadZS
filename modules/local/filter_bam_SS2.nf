process FILTER_BAM_SS2 {
  tag "${bamFileID}"
  label 'process_medium'

  conda (params.enable_conda ? 'bioconda::pysam=0.17.0 conda-forge::python=3.9.5' : null)

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
    --input_bam ${bam} \\
    --isSICILIAN ${isSICILIAN} \\
    --isCellranger ${isCellranger} \\
    --libType ${libType} \\
    --bamName ${bamFileID} \\
    --inputChannel ${inputChannel}
  """
}
