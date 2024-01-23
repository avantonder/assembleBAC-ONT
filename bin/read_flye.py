#!/usr/bin/env python

from collections import deque
import sys
import glob
import os
import argparse
import pandas as pd

def parser_args(args=None):
    """ 
    Function for input arguments for read_flye.py
    """
    Description = 'Extract assembly statistics from Flye log file'
    Epilog = """Example usage: python read_flye.py """
    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("-o", "--output_file", type=str, default="flye_stats.tsv", help="Flye assembly metrics file (default: 'flye_stats.tsv').")
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

def extract_stats(flye_logs):
    """ 
    Function for converting assembly stats extracted from flye log
    into a dataframe 
    """
    log_names = [i.replace('.flye.log', '') for i in flye_logs]
    log_names_df = pd.DataFrame(log_names)
    log_names_df.columns = ['Sample']

    last_eight_lines = {}

    for index, file in enumerate(flye_logs):
        with open(file, 'r') as file:
            # Use deque to keep the last 8 lines
            q = deque(file, maxlen = 8)
            q_list = list(q)
            q_list = pd.DataFrame(q_list)
            df = q_list.iloc[:-2]
            df = df.replace('\n','', regex=True)
            df = df.replace(':','', regex=True)
            split_df = df[0].str.split('\t', expand=True).T
            split_df.rename(columns=split_df.iloc[1], inplace = True)
            split_df = split_df.iloc[2:3]
            split_df = split_df.reset_index(drop=True)
            last_eight_lines[index] = split_df
            
    all_df = pd.concat(last_eight_lines, ignore_index=True)
    merged_df = log_names_df.join(all_df)

    return merged_df

def main(args=None):
    args = parser_args(args)

    ## Create output directory if it doesn't exist
    out_dir = os.path.dirname(args.output_file)
    make_dir(out_dir)

    ## Read
    flye_logs = sorted(glob.glob('*.flye.log'))

    ## Create dataframe
    flye_df = extract_stats(flye_logs)

    ## Write output file
    flye_df.to_csv(args.output_file, sep = '\t', header = True, index = False)

if __name__ == '__main__':
    sys.exit(main())