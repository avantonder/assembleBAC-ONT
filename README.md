# assembleBAC-ONT

# ![avantonder/assembleBAC-ONT](docs/images/assembleBAC-ONT_metromap.png)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/assemblebacont)

## Introduction

**avantonder/assembleBAC-ONT** is a bioinformatics pipeline that *de novo* assembles and annotates Oxford Nanopore (ONT) long-read sequence data.

1. Aggregate pre-demultiplexed reads from MinKNOW/Guppy ([`artic guppyplex`](https://artic.readthedocs.io/en/latest/commands/))
2. Filter long reads ([`Filtlong`](https://github.com/rrwick/Filtlong))
3. Downsample fastq files ([`Rasusa`](https://github.com/mbhall88/rasusa))
4. Remove adapter sequences ([`Porechop`](https://github.com/rrwick/Porechop))
5. *de novo* assembly ([`Flye`](https://github.com/fenderglass/Flye))
6. Polish assemblies with ONT data ([`Medaka`](https://nanoporetech.github.io/medaka/index.html))
7. Assembly metrics ([`Quast`](https://quast.sourceforge.net/))
8. Assembly completeness ([`CheckM2`](https://github.com/chklovski/CheckM2))
9. Sequence Type assignment ([`mlst`](https://github.com/tseemann/mlst))
10. Annotation ([`Bakta`](https://github.com/oschwengers/bakta))
11. Present QC, visualisation and custom reporting for filtering and assembly results ([`MultiQC`](http://multiqc.info/))

## Quick Start

1. Install [`nextflow`](https://nf-co.re/usage/installation)(`>=23.04.0`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(please only use [`Conda`](https://conda.io/miniconda.html) as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_

3. Download the `Bakta` light database (`Bakta` is required to run the `amrfinder_update` command):

    ```bash
    wget https://zenodo.org/record/7669534/files/db-light.tar.gz
    tar -xzf db-light.tar.gz
    rm db-light.tar.gz
    amrfinder_update --force_update --database db-light/amrfinderplus-db/
    ```

4. Download the `CheckM2` database (`CheckM2` is required):

    ```bash
    checkm2 database --download --path path/to/checkm2db
    ```

3. Download the pipeline and test it on a minimal dataset with a single command:

   ```bash
   nextflow run avantonder/assembleBAC-ONT -profile test,YOURPROFILE --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   > - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Start running your own analysis!
    - Typical command for assembly and annotation

    ```bash
    nextflow run avantonder/assembleBAC-ONT \
        -profile singularity \
        -c <INSTITUTION>.config \
        --input samplesheet.csv \
        --fastq_dir path/to/fastq/files \
        --genome_size <ESTIMATED GENOME SIZE e.g. 4M> \
        --medaka_model <MEDAKA MODEL> \
        --min_read_length <MINIMUM READ LENGTH> \
        --outdir <OUTDIR> \
        --baktadb path/to/baktadb/dir \
        --checkm2db path/to/checkm2db/diruniref100.KO.1.dmnd \
        -resume
    ```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

## Documentation

The avantonder/assembleBAC-ONT pipeline comes with documentation about the pipeline [usage](docs/usage.md), [parameters](docs/parameters.md) and [output](docs/output.md).

## Credits

avantonder/assembleBAC-ONT was originally written by Andries van Tonder.  I wouldn't have been able to write this pipeline with out the tools, documentation, pipelines and modules made available by the fantastic [nf-core community](https://nf-co.re/). In particular, the excellent viralrecon pipeline was a source of code and inspiration. Finally, a shout out to Robert Petit's [Dragonflye](https://github.com/rpetit3/dragonflye) as an additional source of inspiration.

## Feedback

If you have any issues, questions or suggestions for improving assembleBAC-ONT, please submit them to the [Issue Tracker](https://github.com/avantonder/assembleBAC-ONT/issues).

## Citations

If you use the avantonder/assembleBAC-ONT pipeline, please cite it using the following doi: ZENODO_DOI

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
