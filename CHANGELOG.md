# avantonder/assembleBAC-ONT: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.0.3 - [18/06/2025]

### `Fixed`

- Fix `process.shell` in `nextflow.config` ([#3416](https://github.com/nf-core/tools/pull/3416))

## v2.0.2 - [21/03/2025]

### `Fixed`

- Documentation updated
- Flye assembly_info.txt files now included in results

## v2.0.1 - [17/03/2025]

### `Fixed`

- Documentation updated
- DOI generated with Zenodo

## v2.0.0 - [06/03/2025]

### `Added`

- Significant recoding of pipeline to bring it more in line with current nf-core template
- Python script provided to create new samplesheet format
- Option to QC raw reads using FastQC (default) or Falco added
- Option to use porechop or porechop_abi (default) for adapter removal
- Option to filter reads with nanoq (default) or filtlong
- Falco version 1.2.1 added to pipeline
- FastQC version 0.12.1 added to pipeline  
- nanoq version 0.10.0 added to pipeline
- Porechop_abi version 0.5.0 added to pipeline
 
 ### `Fixed`

- ARTIC no longer required to create sample list 
- Update Bakta from version 1.7.0 to version 1.10.4
- Update Flye from version 2.9 to version 2.9.5
- Update Medaka from version 1.11.3 to version 2.0.1
- Medaka model files are now pulled from the Medaka Github page
- Update mlst from version 2.19.0 to version 2.23.0
- Update MultiQC from version 1.14 to version 1.25.1


## v1.1.1 - [08/02/2024]

### `Added`

-Update `Medaka` to version 1.11.3

## v1.1 - [23/01/2024]

### `Added`

- Parse Flye output logs to produce `flye_stats.tsv` summary file in `metadata` directory
- Save Flye `.gfa.gz` assembly graph files in `flye` directory
- List Flye data options in `parameters.md`

### `Fixed`

- Rename `--subsampling_off` to `--skip_subsampling`
- Corrected ARCTIC to ARTIC in metromap figure

## v1.0.0 - [20/09/2023]

Initial release of avantonder/assembleBAC-ONT, created with the [nf-core](https://nf-co.re/) template.
