# avantonder/assembleBAC-ONT: Output

## Introduction

This document describes the output produced by the `assembleBAC-ONT` pipeline. The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [FastQC](#fastqc) - Raw read QC
- [falco](#fastqc) - Alternative to FastQC for raw read QC
- [Porechop](#porechop) - Adapter removal for Oxford Nanopore data
- [Porechop_ABI](#porechop_abi) - Adapter removal for Oxford Nanopore data
- [Filtlong](#filtlong) - Quality trimming and filtering for Nanopore data
- [Nanoq] (#nanoq) - Quality trimming and filtering for Nanopore data 
- [Read subsampling](#read-subsampling)
- [Remove adapter sequences](#remove-adapter-sequences)
- [*de novo* genome assembly](#de-novo-genome-assembly)
- [Sequence Type assignment](#sequence-type-assignment)
- [Genome annotation](#genome-annotation)
- [Genome completeness](#genome-completeness)
- [Assembly metrics](#assembly-metrics) 
- [MultiQC](#multiqc)
- [Pipeline information](#pipeline-information)

### FastQC or Falco

<details markdown="1">
<summary>Output files</summary>

- `{fastqc,falco}/`
  - {raw,preprocessed}
    - `*html`: FastQC or Falco report containing quality metrics in HTML format.
    - `*.txt`: FastQC or Falco report containing quality metrics in TXT format.
    - `*.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images (FastQC only).

</details>

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

If preprocessing is turned on, nf-core/taxprofiler runs FastQC/Falco twice -once before and once after adapter removal/read merging, to allow evaluation of the performance of these preprocessing steps. Note in the General Stats table, the columns of these two instances of FastQC/Falco are placed next to each other to make it easier to evaluate. However, the columns of the actual preprocessing steps (i.e, fastp, AdapterRemoval, and Porechop) will be displayed _after_ the two FastQC/Falco columns, even if they were run 'between' the two FastQC/Falco jobs in the pipeline itself.

:::info
Falco produces identical output to FastQC but in the `falco/` directory.
:::

![MultiQC - FastQC sequence counts plot](images/mqc_fastqc_counts.png)

![MultiQC - FastQC mean quality scores plot](images/mqc_fastqc_quality.png)

![MultiQC - FastQC adapter content plot](images/mqc_fastqc_adapter.png)

:::note
The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and potentially regions with low quality.
:::

### Porechop

[Porechop](https://github.com/rrwick/Porechop) is a tool for finding and removing adapters from Oxford Nanopore reads. Adapters on the ends of reads are trimmed and if a read has an adapter in its middle, it is considered a chimeric and it chopped into separate reads.

<details markdown="1">
<summary>Output files</summary>

- `porechop/`
  - `<sample_id>.log`: Log file containing trimming statistics
  - `<sample_id>.fastq.gz`: Adapter-trimmed file

</details>

The output logs are saved in the output folder and are part of MultiQC report.You do not normally need to check these manually.

You will only find the `.fastq` files in the results directory if you provide ` --save_preprocessed_reads`. Alternatively, if you wish only to have the 'final' reads that go into classification/profiling (i.e., that may have additional processing), do not specify this flag but rather specify `--save_analysis_ready_reads`, in which case the reads will be in the folder `analysis_ready_reads`.

:::warning
We do **not** recommend using Porechop if you are already trimming the adapters with ONT's basecaller Guppy.
:::

### Porechop_ABI

[Porechop_ABI](https://github.com/bonsai-team/Porechop_ABI) is an extension of [Porechop](https://github.com/rrwick/Porechop). Unlike Porechop, Porechop_ABI does not use any external knowledge or database for the adapters. Adapters are discovered directly from the reads using approximate k-mers counting and assembly. Then these sequences can be used for trimming, using all standard Porechop options. The software is able to report a combination of distinct sequences if a mix of adapters is used. It can also be used to check whether a dataset has already been trimmed out or not, or to find leftover adapters in datasets that have been previously processed with Guppy.

<details markdown="1">
<summary>Output files</summary>

- `porechop_abi/`
  - `<sample_id>.log`: Log file containing trimming statistics
  - `<sample_id>.fastq.gz`: Adapter-trimmed file

</details>

The output logs are saved in the output folder and are part of MultiQC report.You do not normally need to check these manually.

You will only find the `.fastq` files in the results directory if you provide ` --save_preprocessed_reads`. Alternatively, if you wish only to have the 'final' reads that go into classification/profiling (i.e., that may have additional processing), do not specify this flag but rather specify `--save_analysis_ready_reads`, in which case the reads will be in the folder `analysis_ready_reads`.

### Filtlong

[Filtlong](https://github.com/rrwick/Filtlong) is a quality filtering tool for long reads. It can take a set of small reads and produce a smaller, better subset.

<details markdown="1">
<summary>Output files</summary>

- `filtlong/`
  - `<sample_id>_filtered.fastq.gz`: Quality or long read data filtered file
  - `<sample_id>_filtered.log`: log file containing summary statistics

</details>

You will only find the `.fastq` files in the results directory if you provide ` --save_preprocessed_reads`. Alternatively, if you wish only to have the 'final' reads that go into classification/profiling (i.e., that may have additional processing), do not specify this flag but rather specify `--save_analysis_ready_reads`, in which case the reads will be in the folder `analysis_ready_reads`.

:::warning
We do _not_ recommend using Filtlong if you are performing filtering of low quality reads with ONT's basecaller Guppy.
:::

### Nanoq

[nanoq](https://github.com/esteinig/nanoq) is an ultra-fast quality filtering tool that also provides summary reports for nanopore reads.

<details markdown="1">
<summary>Output files</summary>

- `nanoq/`
  - `<sample_id>_filtered.fastq.gz`: Quality or long read data filtered file
  - `<sample_id>_filtered.stats`: Summary statistics report

</details>

You will only find the `.fastq` files in the results directory if you provide ` --save_preprocessed_reads`. Alternatively, if you wish only to have the 'final' reads that go into classification/profiling (i.e., that may have additional processing), do not specify this flag but rather specify `--save_analysis_ready_reads`, in which case the reads will be in the folder `analysis_ready_reads`.

### Read Subsampling

[rasusa](https://github.com/mbhall88/rasusa) is used to subsample reads to a depth cutoff of a default of 100.

<details markdown="1">
<summary>Output files</summary>

* `rasusa/`
    * `*.fastq.gz` subsampled fastq files

</details>



### *de novo* genome assembly

[Flye](https://github.com/fenderglass/Flye) assembles bacterial isolate genomes from Oxford Nanopore reads.

<details markdown="1">
<summary>Output files</summary>

- `flye/`
  - `*_log`: Flye log files

</details>

### Sequence Type assignment

[mlst](https://github.com/tseemann/mlst) is used to assign Sequence Types (STs) to bacterial isolate genomes.

<details markdown="1">
<summary>Output files</summary>

- `mlst/`
  - `*.tsv`: MLST calls in tsv format
- `metadata/`
  - `mlst_summary.tsv`: mlst summary in tsv format

</details>

### Genome annotation

[Bakta](https://github.com/oschwengers/bakta) is used for the annotation of bacterial genomes (isolates, MAGs) and plasmids.

<details markdown="1">
<summary>Output files</summary>

- `bakta/`
  - `*.gff3`: Annotations & sequences in GFF3 format

</details>

### Genome completeness

[CheckM2](https://github.com/chklovski/CheckM2) is used for the rapid assessment of genome bin quality using machine learning

<details markdown="1">
<summary>Output files</summary>

- `checkm2/`
  - `*.tsv`: CheckM2 output in tsv format
- `metadata/`
  - `checkm2_summary.tsv`: CheckM2 summary in tsv format

</details>

### Assembly metrics

[Quast](https://quast.sourceforge.net/) is a quality assessment tool for genome assemblies.

<details markdown="1">
<summary>Output files</summary>

- `metadata/`
  - `transposed_report.tsv`: Quast summary in tsv format

</details>

### MultiQC

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
