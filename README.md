# ![nf-core/readzs](docs/images/nf-core-readzs_logo.png)

[![GitHub Actions CI Status](https://github.com/nf-core/readzs/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/readzs/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/nf-core/readzs/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/readzs/actions?query=workflow%3A%22nf-core+linting%22)
[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/readzs/results)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.04.0-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23readzs-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/readzs)
[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)
[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

# Introduction

<!-- TODO nf-core: Write a 1-2 sentence summary of what data the pipeline is for and what it does -->
**salzmanlab/readzs** is a bioinformatics best-practice analysis pipeline for The Read Z-score (ReadZS), a metric that summarizes the transcriptional state of a gene in a single cell.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!


## Pipeline summary

![nf-core/readzs](docs/images/readzs_pipeline.png)


1. Filter and quantify read enrichment from bam files
2. Calculate the ReadZS (read z-score) for single cells across genomic bins
3. Downstream analyses
    1. Aggregate the ReadZS along cell-type annotations and identify windows of interest
    2. Plot read distributions for cell-types in windows of interest
    3. Perform GMM-based subclustering to identify peaks
    4. Annotate peaks with distances to annotated features


# Quick Start
1. Install [`nextflow`](https://nf-co.re/usage/installation) (`>=20.04.0`) and [`conda`](https://docs.conda.io/en/latest/).

2. Create conda environment and activate.
    ```bash
    conda env create --name readzs_env --file=environment.yml
    conda activate readzs_env
    ```
3. Run the pipeline on test data.
    ```bash
    nextflow run salzmanlab/readzs \
        -latest \
        -profile conda,small_test_data
    ```

    [Sherlock](https://www.sherlock.stanford.edu/) users should use the `sherlock` profile:


        nextflow run salzmanlab/readzs \
            -latest \
            -profile conda,small_test_data,sherlock



4. To run on other datasets, modify a config file with data-specific parameters, using `conf/test.config` as a template. You may need to modify the [executor scope](https://www.nextflow.io/docs/latest/executor.html) in the config file, in accordance to your compute needs.


# Input Arguments

| Argument                | Description     |Example Usage  |
| -----------             | -----------     |-----------|
| `runName`               | Descriptive name for ReadZS run, used in the final output files |*Tumor_5* |
| `input`      | Input samplesheet in csv format, format described below | `Tumor_5_samplesheet.csv` |
| `useChannels`            | `true` if the same samples were split across multiple lanes with barcode overlap between samples | `true`, `false` |
| `isSICILIAN`            | If the input bam files are output from [SICILIAN](https://github.com/salzmanlab/SICILIAN)| `true`, `false` |
| `isCellranger`          | `true` if input data is output from Cellranger | `true`, `false` |
| `ontologyCols	`         | Double-encapsulated list string describing the `metadata` columns that will create the cell-type variable | *"'tissue, compartment, annotation'"* |
| `metadata`              | Path to cell-type annotation file, described below | `metadata_Tumor5.tsv` |
| `chr_lengths`           | Two-column, tab-delimited file containing chromosome names in the first column and chromosome lengths in the second column. Chromosome names must match those in bam files. | */home/refs/human.chrs* |
| `gff`                   | Location of genome GFF file, used for plotting; can be obtained from [GENCODE](https://www.gencodegenes.org/human/) | */home/refs/humanv37.gff* |
| `annotation_bed`        | BED-formatted file, used to annotate the windows, e.g. "refFlat" table of genes in BED format obtained from [UCSC Table Browser](https://genome.ucsc.edu/cgi-bin/hgTables)| */home/refs/hg38_genes.bed*  |

## Default Parameters
These default values can be modified to suit the needs of your data.
| Argument                | Description     | Default Value  |
| -----------             | -----------     |-----------|
| `binSize`               | Size of genomic bins, used to calculate z-scores | *5000*  |
| `minCellsPerWindowOnt`  | Minimum cells per window-ontology required to calculate medians for that window-ontology | *20*  |
| `minCtsPerCell`         | Minimum counts per cell for a window required to include this cell in calculating medians for that window-ontology| *10*  |
| `nPermutations`         | Number of permutations to be used in median calculation | *1000* |
| `nGenesToPlot`          | Number of top windows to generate read distribution histograms for| *20* |
| `peak_method`           | Subclustering method for calling peaks, options: `knee`, `max` | `knee` |

## Pipeline Parameters
By default, these boolean parameters are all `false`, in order to run every step of the pipeline. These parameters can be used to modify which steps are run, or to re-run analysis steps on previously completed steps.
| Argument                | Description     | Additional requirements  |
| -----------             | -----------     |-----------|
| `zscores_only`          | Calculate ReadZS values for cells over genomic bins, without annotating cells with cell-types or any downstram analyses. | If `true`, `plot_only` and `subcluster_only` cannot be `true` |
| `skip_plot`             | Run all steps of pipeline, except for plot generation of read distributions. | If `true`, `plot_only` cannot be `true` |
| `skip_subcluster`       | Run all steps of pipeline, except for subclustering/peak calling. | If `true`, `subcluster_only` cannot be `true`  |
| `plot_only`             | If all steps up to median calculation have been previously performed, only perform plot generation of read distributions. | `all_pvals_path` , `resultsDir`|
| `subcluster_only`       | If all steps up to annotation steps have been previously performed, only perform subclustering/peak calling.| `counts_path`, `ann_pvals_path`|
| (`--plot_only`) `all_pvals_path`        | Path to all_pvals file, containing a `windows` column. | *home/results/results/annotated_files/`${runName}`_all_pvals.txt* |
| (`--plot_only`) `resultsDir`            | Path to results directory of previous run. | *home/results*  |
| (`--subcluster_only`) `counts_path`           | Path to results directory for counts files. | *home/results/counts* |
| (`--subcluster_only`) `ann_pvals_path`        | Path to ann_pvals file. | *home/results/results/annotated_files/`${runName}`_ann_pvals.txt* |

## File Descriptions
#### `input`
The samplesheet should be comma-delimited(no spaces after the comma), with no header.

If `useChannels = true`, the file will have 3 columns:
* channel name (i.e. *Tumor5_bladder*)
* file identifier (i.e. *Tumor5_bladder_L001*)
* path to bam file (i.e. *data/Tumor5_bladder_001.bam*)

If `useChannels = false`, the file will have 2 columns:
* file identifier (i.e. *Tumor5_bladder_L001*)
* path to bam file (i.e. *data/Tumor5_bladder_001.bam*)

#### `metadata`
This file should contain the following columns:
* cell_id
    * Cell identification column, with each row structured as "${channel}_barcode"
    * If `useChannels = false`, each row should be structured as "${file_identifier}_barcode"
    * Example cell_id value:
        * "Tumor5_AACCATGCAGCTCGCA"
* Metadata columns used to define the ontology (grouping for which the median z-score will be calculated)
    * Examples:
        * tissue, compartment, annotation
        * ontology = "lung_immune_macrophage"

# Output
## Files
* Significant windows
    * `results/${runName}/medians/${runName}_*_medians_*.txt`
        * List of all median values for cells in window-ontologies passing filter
    * `results/${runName}/signif_medians/${runName}_*_medians_*.txt`
        * List of significant median values for all cells in window-ontologies passing filter
    * `results/${runName}/annotated_files/${runName}_all_pvals.txt`
        * All windows, annotated with `annotation_bed`
    * `results/${runName}/annotated_files/${runName}_ann_pvals.txt`
        * All significant windows, annotated with `annotation_bed` and ranked by effect size
        * Rankings from this file are used to rank plotted windows and windows for calling peaks
    * `results/${runName}/annotated_files/annotated_windows.file`
        * Bed file of windows of size = `binSize`, with each window annotated with `annotation_bed`
* Peaks
    * `results/${runName}/peaks/${runName}_${peak_method}_peaks.tsv`
        * Peaks called for each significant window, with one peak per line
* Plots
    * `results/${runName}/plots/*.png`
        * Read distributions of the top 2 and bottom ontologies of each significant window, as ranked by effect size

#### `results/${runName}/signif_medians/${runName}_*_medians_*.txt`
| Field      | Description |
| ----------- | ----------- |
| `window`                           | Stranded window from genome, as created by `windowsFile`|
| `ontology`                         | Metadata grouping, as created by `ontologyCols` |
| `sum_counts_per_window_per_ont`    | Total read counts per window-ontology |
| `med_counts_per_window_per_ont`    | Median read counts per window-ontology |
| `median_z_scaled`                  | Median z-scaled value of the window-ontology |
| `chi2_p_val`                       | Chi<sup>2</sup> of `median_z_scaled` |
| `perm_p_val`                       | Permutation p-value of `median_z_scaled`       |
| `significant`                      | Is `perm_p_val` signficant|
| `medians_range`                    | Range of median z-scores for all ontologies in a window     |

#### `results/${runName}/peaks/${runName}_${peak_method}_peaks.tsv`
| Field      | Description |
| ----------- | ----------- |
| `window`                           | Significant window, as ranked by effect size|
| `num_peaks`                         | Number of peaks per window |
| `peak_pos`    | Peak position|
| `comp_prob`    | Component probability  |
| `ICL_vec`                  | The vector of ICL criterion values for each number if components |

## Credits

nf-core/readzs was originally written by the Salzman Lab.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  nf-core/readzs for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->
An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **ReadZS detects developmentally regulated RNA processing programs in single cell RNA-seq and defines subpopulations independent of gene expression**
>
> Elisabeth Meyer, Roozbeh Dehghannasiri, Kaitlin Chaung, Julia Salzman.
>
> _bioRxiv_ 2021 Oct 01. doi: [10.1101/2021.09.29.462469](https://doi.org/10.1101/2021.09.29.462469).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
