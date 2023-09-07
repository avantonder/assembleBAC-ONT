#!/usr/bin/env python3

import os
import sys
import glob
import argparse
import pandas as pd

def parser_args(args=None):
    """ 
    Function for input arguments for checkm2_parser.py
    """
    Description = 'Collect checkm2 outputs and create a summary table'
    Epilog = """Example usage: python checkm2_parser.py """
    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("-of", "--output_file", type=str, default="checkm2_summary.tsv", help="checkm2 summary file (default: 'checkm2_summary.tsv').")
    return parser.parse_args(args)

def make_dir(path):
    """ 
    Function for making a directory from a provided path
    """
    if not len(path) == 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise

def checkm2_to_dataframe(file_list):
    """ 
    Function for creating a dataframe from a list of checkm2 output files
    """
    file_read = [pd.read_csv(f, sep='\t') for f in file_list]
    df = pd.concat(file_read, ignore_index=True)

    return df

def main(args=None):
    args = parser_args(args)

    ## Create output directory if it doesn't exist
    out_dir = os.path.dirname(args.output_file)
    make_dir(out_dir)

    ## Create list of checkm2 tsv outputs
    checkm2_files = sorted(glob.glob('*.tsv'))

    ## Create dataframe
    checkm2_df = checkm2_to_dataframe(checkm2_files)

    ## Write output file
    checkm2_df.to_csv(args.output_file, sep = '\t', header = True, index = False)

if __name__ == '__main__':
    sys.exit(main())