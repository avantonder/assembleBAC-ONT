#!/usr/bin/env python

import os
import csv
import argparse
import sys

def parser_args(args=None):
    """ 
    Function for input arguments for build_samplesheet.py
    """
    Description = 'Create samplesheet from ONT barcode directories with multiple fastq files for each sample'
    Epilog = """Example usage: python build_samplesheet.py -i input_directory """
    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("-i", "--input_directory", type=str, default="data/fastq_pass", help="Path to directory containing barcode directories.")
    return parser.parse_args(args)

def find_fastq_files_in_barcode_dirs(root_dir, output_csv):
    """ 
    Function for finding fastq files in barcode directories
    """
    # Open the CSV file for writing
    with open(output_csv, mode='w', newline='') as csv_file:
        writer = csv.writer(csv_file)
        # Write the header
        writer.writerow(['sample', 'fastq'])

        # Walk through the directory tree
        for dirpath, dirnames, filenames in os.walk(root_dir):
            # Check if the current directory name starts with 'barcode'
            if os.path.basename(dirpath).startswith('barcode'):
                sample_name = os.path.basename(dirpath)  # Use the directory name as the sample name
                for filename in filenames:
                    # Check if the file ends with '.fastq'
                    if filename.endswith('.fastq.gz'):
                        # Write the sample name and full file path to the CSV
                        full_path = os.path.join(dirpath, filename)
                        writer.writerow([sample_name, full_path])
def main(args=None):
    args = parser_args(args)

    # Specify the root directory where the search should begin
    root_directory = args.input_directory

    # Specify the output CSV file path
    output_csv_file = 'samplesheet.csv'

    # Get the list of fastq files in directories starting with 'barcode' and write to CSV
    find_fastq_files_in_barcode_dirs(root_directory, output_csv_file)

    print(f"CSV file '{output_csv_file}' has been created.")

if __name__ == '__main__':
    sys.exit(main())
