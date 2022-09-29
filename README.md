
# Introduction

<!-- TODO nf-core: Write a 1-2 sentence summary of what data the pipeline is for and what it does -->
**salzmanlab/readzs** is a bioinformatics best-practice analysis pipeline for The Read Z-score (ReadZS), a metric that summarizes the transcriptional state of a gene in a single cell. [About the ReadZS](https://doi.org/10.1101/2021.09.29.462469)

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).
> **The nf-core framework for community-curated bioinformatics pipelines.**
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).



## Pipeline summary

![nf-core/readzs](docs/images/readzs_pipeline.png)


1. Filter and quantify read enrichment from BAM files
2. Calculate the ReadZS (read z-score) for single cells across genomic bins
3. Downstream analyses
    a. Aggregate the ReadZS along cell type annotations and identify windows with significant cell type-specific regulation
    b. Plot read distributions for cell types in windows of interest
    c. Perform GMM-based subclustering to identify peaks in read distributions
    d. Annotate peaks with distances to annotated features



# Quick Start
1. Install [`nextflow`](https://nf-co.re/usage/installation) (`>=20.04.0`) and [`conda`](https://docs.conda.io/en/latest/).

2. Run the pipeline on test data.
    ```bash
    nextflow run salzmanlab/readzs \
        -r master \
        -latest \
        -profile small_test_data
    ```

    Stanford [Sherlock](https://www.sherlock.stanford.edu/) users should use the `sherlock` profile:

        nextflow run salzmanlab/readzs \
            -r master \
            -latest \
            -profile small_test_data,sherlock

3. To run on other datasets, modify a config file with data-specific parameters, using `conf/test.config` as a template. **Note: do not include dashes in the run names or channel names.** You may need to modify the [executor scope](https://www.nextflow.io/docs/latest/executor.html) in the config file, in accordance to your compute needs.



# Input Arguments

| Argument                | Description     |Example Usage  |
| -----------             | -----------     |-----------|
| `runName`               | Descriptive name for ReadZS run, used in the final output files. Note: the run name should not contain any dashes (-). |*Tumor_5* |
| `input`      | Input samplesheet in csv format, format described below | `Tumor_5_samplesheet.csv` |
| `useChannels`            | `true` if the same samples were split across multiple sequencer lanes, with barcode overlap between different samples | `true`, `false` |
| `isSICILIAN`            | If the input bam files are output from [SICILIAN](https://github.com/salzmanlab/SICILIAN)| `true`, `false` |
| `isCellranger`          | `true` if input data is output from Cellranger | `true`, `false` |
| `ontologyCols	`         | Double-encapsulated list string describing the `metadata` columns that will create the "ontology" variable, e.g. cell type | *"'tissue, compartment, annotation'"* |
| `metadata`              | Path to metadata (e.g. cell type) annotation file, described below | `metadata_Tumor5.tsv` |
| `chr_lengths`           | Two-column, tab-delimited file containing chromosome names in the first column and chromosome lengths in the second column. Chromosome names must match those in BAM files. | */home/refs/human.chrs* |
| `gff`                   | Location of genome GFF file, used for plotting; can be obtained from [GENCODE](https://www.gencodegenes.org/human/) | */home/refs/humanv37.gff* |
| `annotation_bed`        | BED-formatted file, used to annotate the windows, e.g. "refFlat" table of genes in BED format obtained from [UCSC Table Browser](https://genome.ucsc.edu/cgi-bin/hgTables)| */home/refs/hg38_genes.bed*  |


## Default Parameters
These default values can be modified to suit the needs of your data.
| Argument                | Description     | Default Value  |
| -----------             | -----------     |-----------|
| `binSize`               | Size of genomic bins ("windows"), used to calculate z-scores | *5000*  |
| `minCellsPerWindowOnt`  | Minimum cells per window-ontology required to calculate medians for that window-ontology | *20*  |
| `minCtsPerCell`         | Minimum counts per cell for a window required to include this cell in calculating medians for that window-ontology| *10*  |
| `nPermutations`         | Number of permutations to be used in significance calculation | *1000* |
| `numPlots`          | Number of top windows to generate read distribution histograms for| *20* |
| `peak_method`           | Subclustering method for calling peaks, options: `knee`, `max` | `knee` |
| `zscores_only`          | Calculate ReadZS values for cells over genomic bins, without annotating cells with cell-types or any downstram analyses. | `false` |
| `skip_plot`             | Run all steps of pipeline, except for plot generation of read distributions. | `false` |
| `skip_subcluster`       | Run all steps of pipeline, except for subclustering/peak calling. | `false` |
| `plot_only`             | If all steps up to median calculation have been previously performed, only perform plot generation of read distributions. | `false`|
| `subcluster_only`       | If all steps up to annotation steps have been previously performed, only perform subclustering/peak calling.| `false`|


## `plot_only` Parameters

Example run command:

```
nextflow run salzmanlab/readzs \
    --plot_only true \
    --input Tumor_5_samplesheet.csv \
    --all_pvals_path *home/results/results/annotated_files/`${runName}`_all_pvals.txt* \
    --resultsDir *home/results* \
    --runName Tumor5 \
    --ontologyCols "'tissue, compartment, annotation'" \
    --gff genome.gff
```

| Argument                | Description     | Example Usage  |
| -----------             | -----------     |-----------|
| `input`      | Input samplesheet in csv format, format described below | `Tumor_5_samplesheet.csv` |
| `all_pvals_path`        | Path to all_pvals file generated by previous ReadZS run, containing a `windows` column. | *home/results/results/annotated_files/`${runName}`_all_pvals.txt* |
| `resultsDir`            | Path to results directory of previous run. | *home/results*  |
| `runName`               | Descriptive name for ReadZS run, used in the final output files |*Tumor_5* |
| `ontologyCols	`         | Double-encapsulated list string describing the `metadata` columns that will create the "ontology" variable, e.g. cell type | *"'tissue, compartment, annotation'"* |
| `gff`                   | Location of genome GFF file, used for plotting; can be obtained from [GENCODE](https://www.gencodegenes.org/human/) | */home/refs/humanv37.gff* |
| `binSize`               | Size of genomic bins, used to calculate z-scores | **Defaults to 5000**  |
| `numPlots`          | Number of top windows to generate read distribution histograms for| **Defaults to 20** |

## `peaks_only` Parameters

Example run command:

```
nextflow run salzmanlab/readzs \
    --peaks_only true \
    --input Tumor_5_samplesheet.csv \
    --counts_path home/results/counts \
    --ann_pvals_path home/results/results/annotated_files/`${runName}`_ann_pvals.txt \
    --runName Tumor5
```

| Argument                | Description     | Example Usage  |
| -----------             | -----------     |-----------|
| `input`      | Input samplesheet in csv format, format described below | `Tumor_5_samplesheet.csv` |
| `counts_path`           | Path to directory containing counts files, in results directory of previous ReadZS run. | *home/results/counts* |
| `ann_pvals_path`        | Path to ann_pvals file generated by previous ReadZS run. | *home/results/results/annotated_files/`${runName}`_ann_pvals.txt* |
| `runName`               | Descriptive name for ReadZS run, used in the final output files |*Tumor_5* |
| `peak_method`           | Subclustering method for calling peaks, options: `knee`, `max` | **Defaults to `knee`** |


## File Descriptions
#### `input`
The samplesheet specifies the BAM files to be used. It should be comma-delimited (no spaces after the comma), with no header.

If `useChannels = true`, the file must have 3 columns:
* channel name (i.e. *Tumor5_bladder*)
* file identifier (i.e. *Tumor5_bladder_L001*)
* path to bam file (i.e. *data/Tumor5_bladder_001.bam*)

If `useChannels = false`, the file must have 2 columns:
* file identifier (i.e. *Tumor5_bladder_L001*)
* path to bam file (i.e. *data/Tumor5_bladder_001.bam*)

#### `metadata`
The metadata gives additional information about each cell, to be used for calculation of median ReadZS and significance calculation. The metadata file should contain the following columns:
* cell_id
    * Cell identification column, with each entry structured as "${channel}_barcode"
    * If `useChannels = false`, each entry should be structured as "${file_identifier}_barcode"
    * Example cell_id value:
        * "Tumor5_AACCATGCAGCTCGCA"
* Metadata columns used to define the ontology (grouping for which the median ReadZS will be calculated)
    * Examples:
        * tissue, compartment, annotation
        * ontology = "lung_immune_macrophage"


# Output
## Files
* Significant windows (genomic windows determined to have significant ontology-specific differences in RNA processing):
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
* Peaks (peaks in read distributions across ALL cells, as determined by the GMM):
    * `results/${runName}/peaks/${runName}_${peak_method}_peaks.tsv`
        * Peaks called for each significant window, with one peak per line
* Plots (histograms of read distributions, grouped by ontology): 
    * `results/${runName}/plots/*.png`
        * Read distributions of the top 2 and bottom ontologies of each significant window, as ranked by effect size

#### `results/${runName}/signif_medians/${runName}_*_medians_*.txt`
| Field      | Description |
| ----------- | ----------- |
| `window`                           | Stranded window from genome, as created by `windowsFile`|
| `ontology`                         | Metadata grouping, as created by `ontologyCols` |
| `sum_counts_per_window_per_ont`    | Total read counts per window-ontology |
| `med_counts_per_window_per_ont`    | Median read counts per window-ontology |
| `median_z_scaled`                  | Median ReadZS value of the window-ontology |
| `chi2_p_val`                       | Chi<sup>2</sup> p-value for `median_z_scaled` |
| `perm_p_val`                       | Permutation p-value for `median_z_scaled`       |
| `significant`                      | `true` if `perm_p_val` is statistically signficant|
| `medians_range`                    | Range of median ReadZS for all ontologies in a window     |

#### `results/${runName}/peaks/${runName}_${peak_method}_peaks.tsv`
| Field      | Description |
| ----------- | ----------- |
| `window`                           | Significant window, ranked by effect size|
| `num_peaks`                        | Number of peaks per window |
| `peak_pos`                         | Peak position |
| `comp_prob`                        | Component probability  |
| `ICL_vec`                          | The vector of ICL criterion values for each number of components |


## Credits

salzmanlab/readzs was originally written by the Salzman Lab.

We thank the following people for their extensive assistance in the development of this pipeline: Julia Oliveri, Robert Bierman, and Sarthak Satpathy.


## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).


## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  nf-core/readzs for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->
An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite ReadZS and Nextflow as follows:

> **ReadZS detects developmentally regulated RNA processing programs in single cell RNA-seq and defines subpopulations independent of gene expression**
> Elisabeth Meyer, Roozbeh Dehghannasiri, Kaitlin Chaung, Julia Salzman.
> _bioRxiv_ 2021 Oct 01. doi: [10.1101/2021.09.29.462469](https://doi.org/10.1101/2021.09.29.462469).

> **The nf-core framework for community-curated bioinformatics pipelines.**
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
