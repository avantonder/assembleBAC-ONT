# avantonder/assembleBAC-ONT: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.1 - [23/01/2023]

### `Added`

- Parse Flye output logs to produce `flye_stats.tsv` summary file in `metadata` directory
- Save Flye `.gfa.gz` assembly graph files in `flye` directory
- List Flye data options in `parameters.md`

### `Fixed`

- Rename `--subsampling_off` to `--skip_subsampling`
- Corrected ARCTIC to ARTIC in metromap figure

## v1.0.0 - [20/09/2023]

Initial release of avantonder/assembleBAC-ONT, created with the [nf-core](https://nf-co.re/) template.
