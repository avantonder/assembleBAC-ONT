# assembleBAC-ONT

# ![avantonder/assembleBAC-ONT](docs/images/assembleBAC-ONT_metromap.png)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/taxprofiler)


## Introduction

**avantonder/assembleBAC-ONT** is a bioinformatics pipeline that *de novo* assembles and annotates Oxford Nanopore (ONT) long-read sequence data.

1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) or [`falco`](https://github.com/smithlabcode/falco) as an alternative option)
2. Performs optional read pre-processing
   - Adapter clipping and merging ([porechop](https://github.com/rrwick/Porechop), [Porechop_ABI](https://github.com/bonsai-team/Porechop_ABI))
   - Low complexity and quality filtering ([Filtlong](https://github.com/rrwick/Filtlong), [Nanoq](https://github.com/esteinig/nanoq))
3. Downsample fastq files ([`Rasusa`](https://github.com/mbhall88/rasusa))
4. *de novo* assembly ([`Flye`](https://github.com/fenderglass/Flye))
5. Polish assemblies with ONT data ([`Medaka`](https://nanoporetech.github.io/medaka/index.html))
6. Assembly metrics ([`Quast`](https://quast.sourceforge.net/))
7. Assembly completeness ([`CheckM2`](https://github.com/chklovski/CheckM2))
8. Sequence Type assignment ([`mlst`](https://github.com/tseemann/mlst))
9. Annotation ([`Bakta`](https://github.com/oschwengers/bakta))
10. Present QC, visualisation and custom reporting for filtering and assembly results ([`MultiQC`](http://multiqc.info/))

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

You will need to Download the `Bakta` light database (`Bakta` version **1.10.4** is required to run the `amrfinder_update` command):

```bash
wget https://zenodo.org/record/7669534/files/db-light.tar.gz
tar -xzf db-light.tar.gz
rm db-light.tar.gz
amrfinder_update --force_update --database db-light/amrfinderplus-db/
```

Additionally, you will need to download the `CheckM2` database (`CheckM2` is required):

````bash
checkm2 database --download --path path/to/checkm2db
````

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. It has to be a comma-separated file with 2 columns, and a header row as shown in the example below. An executable Python script called [`build_samplesheet.py`](https://github.com/avantonder/assembleBAC-ONT/blob/master/assets/build_samplesheet.py) has been provided to auto-create an input samplesheet based on a directory containing sub-directories with the prefix `barcode` which contain the FastQ files **before** you run the pipeline (requires Python 3 installed locally) e.g.

```bash
wget -L https://github.com/avantonder/assembleBAC-ONT/blob/master/assets/build_samplesheet.py

python build_samplesheet.py -i <FASTQ_DIR> 
```

```csv title="samplesheet.csv"
sample,fastq
SAMPLE_1,path/to/fastq/file1
SAMPLE_1,path/to/fastq/file2
SAMPLE_2,path/to/fastq/file1  
```

Now you can run the pipeline using: 

```bash
nextflow run avantonder/assembleBAC-ONT \
    -profile singularity \
    -c <INSTITUTION>.config \
    --input samplesheet.csv \
    --genome_size <ESTIMATED GENOME SIZE e.g. 4M> \
    --medaka_model <MEDAKA MODEL> \
    --outdir <OUTDIR> \
    --baktadb path/to/baktadb/dir \
    --checkm2db path/to/checkm2db/dir/uniref100.KO.1.dmnd \
    -resume
```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

 Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`<INSTITUTION>.config` in the example command above). You can chain multiple config profiles in a comma-separated string.

> - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
> - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
> - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
> - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

## Documentation

The avantonder/assembleBAC-ONT pipeline comes with documentation about the pipeline [usage](docs/usage.md), [parameters](docs/parameters.md) and [output](docs/output.md).

## Credits

avantonder/assembleBAC-ONT was originally written by Andries van Tonder.  I wouldn't have been able to write this pipeline with out the tools, documentation, pipelines and modules made available by the fantastic [nf-core community](https://nf-co.re/). In particular, the excellent viralrecon pipeline was a source of code and inspiration. Finally, a shout out to Robert Petit's [Dragonflye](https://github.com/rpetit3/dragonflye) as an additional source of inspiration.

## Feedback

If you have any issues, questions or suggestions for improving assembleBAC-ONT, please submit them to the [Issue Tracker](https://github.com/avantonder/assembleBAC-ONT/issues).

## Citations

If you use the avantonder/assembleBAC-ONT pipeline, please cite it using the following doi: ZENODO_DOI

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
