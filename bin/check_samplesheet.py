#!/usr/bin/env python

import os
import sys
import errno
import argparse


def parse_args(args=None):
    Description = "Reformat avantonder/assembleBAC-ONT samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")

    return parser.parse_args(args)

def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check samplesheet -> {}".format(error)
    if context != "" and context_str != "":
        error_str = "ERROR: Please check samplesheet -> {}\n{}: '{}'".format(
            error, context.strip(), context_str.strip()
        )
    print(error_str)
    sys.exit(1)

def check_nanopore_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:

    sample,barcode
    SAMPLE_N,1
    SAMPLE_X,2
    SAMPLE_Z,3

    For an example see:
    https://github.com/nf-core/test-datasets/blob/viralrecon/samplesheet/samplesheet_test_nanopore.csv
    """

    sample_mapping_dict = {}
    with open(file_in, "r") as fin:
        ## Check header
        MIN_COLS = 2
        HEADER = ["sample", "barcode"]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]
        if header[: len(HEADER)] != HEADER:
            print("ERROR: Please check samplesheet header -> {} != {}".format(",".join(header), ",".join(HEADER)))
            sys.exit(1)

        ## Check sample entries
        for line in fin:
            lspl = [x.strip().strip('"') for x in line.strip().split(",")]

            # Check valid number of columns per row
            if len(lspl) < len(HEADER):
                print_error(
                    "Invalid number of columns (minimum = {})!".format(len(HEADER)),
                    "Line",
                    line,
                )
            num_cols = len([x for x in lspl if x])
            if num_cols < MIN_COLS:
                print_error(
                    "Invalid number of populated columns (minimum = {})!".format(MIN_COLS),
                    "Line",
                    line,
                )

            ## Check sample entry
            sample, barcode = lspl[: len(HEADER)]
            if sample.find(" ") != -1:
                print(f"WARNING: Spaces have been replaced by underscores for sample: {sample}")
                sample = sample.replace(" ", "_")
            if sample.find("-") != -1:
                print(f"WARNING: Dashes have been replaced by underscores for sample: {sample}")
                sample = sample.replace("-", "_")
            if not sample:
                print_error("Sample entry has not been specified!", "Line", line)

            ## Check barcode entry
            if barcode:
                if not barcode.isdigit():
                    print_error("Barcode entry is not an integer!", "Line", line)
                else:
                    barcode = "barcode%s" % (barcode.zfill(2))

            ## Create sample mapping dictionary = { sample: barcode }
            if barcode in sample_mapping_dict.values():
                print_error(
                    "Samplesheet contains duplicate entries in the 'barcode' column!",
                    "Line",
                    line,
                )
            if sample not in sample_mapping_dict:
                sample_mapping_dict[sample] = barcode
            else:
                print_error(
                    "Samplesheet contains duplicate entries in the 'sample' column!",
                    "Line",
                    line,
                )

    ## Write validated samplesheet with appropriate columns
    if len(sample_mapping_dict) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(",".join(["sample", "barcode"]) + "\n")
            for sample in sorted(sample_mapping_dict.keys()):
                fout.write(",".join([sample, sample_mapping_dict[sample]]) + "\n")
    else:
        print_error("No entries to process!", "Samplesheet: {}".format(file_in))


def main(args=None):
    args = parse_args(args)

    check_nanopore_samplesheet(args.FILE_IN, args.FILE_OUT)

if __name__ == "__main__":
    sys.exit(main())