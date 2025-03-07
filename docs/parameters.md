

# avantonder/assembleBAC-ONT pipeline parameters                                                                                   
                                                                                                                                   
This pipeline assembles ONT sequence data                                                                                          
                                                                                                                                   
## Input/output options                                                                                                            
                                                                                                                                   
Define where the pipeline should find input data and save output data.                                                             
                                                                                                                                   
| Parameter | Description | Type | Default | Required | Hidden |                                                                   
|-----------|-----------|-----------|-----------|-----------|-----------|                                                          
| `input` | Path to comma-separated file containing information about the samples in the experiment.                               <details><summary>Help</summary><small>You will need to create a design file with information about the samples in your experiment before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row.</small></details>| `string` |  | True |  |                                                                             
| `outdir` | The output directory where the results will be saved. You have to use absolute paths to storage on Cloud    infrastructure. | `string` |  | True |  |                                                                                          
| `email` | Email address for completion summary. <details><summary>Help</summary><small>Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.</small></details>| `string` |  |  |  |                                                                                                                                  
| `multiqc_title` | MultiQC report title. Printed as page header, used for filename if not otherwise specified. | `string` |  |  | |                                                                                                                                  
| `perform_runmerging` | Turn on run merging. | `boolean` | True |  |  |                                                           
| `save_runmerged_reads` | Save reads from samples that went through the run-merging step. | `boolean` | True |  |  |              
                                                                                                                                   
## Generic options                                                                                                                 
                                                                                                                                   
Less common options for the pipeline, typically set in a config file.                                                              
                                                                                                                                   
| Parameter | Description | Type | Default | Required | Hidden |                                                                   
|-----------|-----------|-----------|-----------|-----------|-----------|                                                          
| `version` | Display version and exit. | `boolean` |  |  | True |                                                                 
| `validate_params` | Boolean whether to validate parameters against the schema at runtime | `boolean` | True |  | True |                                                             
| `publish_dir_mode` | Method used to save pipeline results to output directory. <details><summary>Help</summary><small>The Nextflow `publishDir` option specifies which intermediate files should be saved to the output directory. This option tells the pipeline what method should be used to move these files. See [Nextflow                 docs](https://www.nextflow.io/docs/latest/process.html#publishdir) for details.</small></details>| `string` | copy |  | True |     
| `trace_report_suffix` | Suffix to add to the trace report filename. Default is the date and time in the format        yyyy-MM-dd_HH-mm-ss. | `string` |  |  | True |                                                                                     
| `email_on_fail` | Email address for completion summary, only when pipeline fails. <details><summary>Help</summary><small>An email address to send a summary email to when the pipeline is completed - ONLY sent if the pipeline does not exit successfully.</small></details>| `string` |  |  | True |                                                                           
| `plaintext_email` | Send plain-text email instead of HTML. | `boolean` |  |  | True |                                            
| `max_multiqc_email_size` | File size limit when attaching MultiQC reports to summary emails. | `string` | 25.MB |  | True |      
| `monochrome_logs` | Do not use coloured log outputs. | `boolean` |  |  | True |                                                  
| `hook_url` | Incoming hook URL for messaging service <details><summary>Help</summary><small>Incoming hook URL for messaging service. Currently, MS Teams and Slack are supported.</small></details>| `string` |  |  | True |                                   
| `multiqc_config` | Custom config file to supply to MultiQC. | `string` |  |  | True |                                            
| `multiqc_logo` | Custom logo file to supply to MultiQC. File name must also be set in the MultiQC config file | `string` |  |  | True |                                                                                                                             
| `multiqc_methods_description` | Custom MultiQC yaml file containing HTML including a methods description. | `string` |  |  |  |  
| `pipelines_testdata_base_path` | Base URL or local path to location of pipeline test dataset files | `string` |        https://raw.githubusercontent.com/nf-core/test-datasets/ |  |  |                                                                   
| `help_full` | Display help text | `boolean` |  |  |  |                                                                           
| `show_hidden` |  | `boolean` |  |  |  |                                                                                          
                                                                                                                                   
## Institutional config options                                                                                                    
                                                                                                                                   
Parameters used to describe centralised config profiles. These should not be edited.                                               
                                                                                                                                   
| Parameter | Description | Type | Default | Required | Hidden |                                                                   
|-----------|-----------|-----------|-----------|-----------|-----------|                                                          
| `custom_config_version` | Git commit id for Institutional configs. | `string` | master |  | True |                               
| `custom_config_base` | Base directory for Institutional configs. <details><summary>Help</summary><small>If you're running offline, Nextflow will not be able to fetch the institutional config files from the internet. If you don't need them, then this is not a problem. If you do need them, you should download the files from the repo and tell Nextflow where to find them with this parameter.</small></details>| `string` | https://raw.githubusercontent.com/nf-core/configs/master |  | True |                      
| `config_profile_name` | Institutional config name. | `string` |  |  | True |                                                     
| `config_profile_description` | Institutional config description. | `string` |  |  | True |                                       
| `config_profile_contact` | Institutional config contact information. | `string` |  |  | True |                                   
| `config_profile_url` | Institutional config URL link. | `string` |  |  | True |                                                  
                                                                                                                                   
## Preprocessing QC options                                                                                                        
                                                                                                                                   
Options for adapter clipping, quality trimming and pair-merging                                                                    
                                                                                                                                   
| Parameter | Description | Type | Default | Required | Hidden |                                                                   
|-----------|-----------|-----------|-----------|-----------|-----------|                                                          
| `skip_preprocessing_qc` | Specify to skip sequencing quality control of raw sequencing reads | `boolean` |  |  |  |              
| `save_preprocessed_reads` | Save reads from samples that went through the adapter clipping, pair-merging, and length filtering steps for reads | `boolean` |  |  |  |                                                                                             
| `preprocessing_qc_tool` | Falco is designed as a drop-in replacement for FastQC but written in C++ for faster computation. We particularly recommend using falco when using long reads (due to reduced memory constraints), however is also applicable for short reads. | `string` | fastqc |  |  |                                                                                                 
| `perform_longread_qc` | Turns on long read quality control steps (adapter clipping, length filtering etc.) | `boolean` | True |  |  |                                                                
| `longread_adapterremoval_tool` | Specify which tool to use for adapter trimming. | `string` | porechop_abi |  |  |               
| `longread_qc_skipadaptertrim` | Skip long-read trimming | `boolean` |  |  |  |                                                   
| `longread_qc_skipqualityfilter` | Skip long-read length and quality filtering | `boolean` |  |  |  |                             
| `longread_filter_tool` | Specify which tool to use for long reads filtering | `string` | nanoq |  |  |                           
| `longread_qc_qualityfilter_minlength` | Specify the minimum length of reads to be retained | `integer` | 1000 |  |  |            
| `longread_qc_qualityfilter_keeppercent` | Specify the percent of high-quality bases to be retained | `integer` | 90 |  |  |      
| `longread_qc_qualityfilter_minquality` | Nanoq only: specify the minimum average read quality filter (Q) | `integer` | 7 |  |  | 
| `longread_qc_qualityfilter_targetbases` | Filtlong only: specify the number of high-quality bases in the library to be retained |`integer` | 500000000 |  |  |                                                                                                      
                                                                                                                                   
## Sub-sampling options                                                                                                            
                                                                                                                                   
                                                                                                                                   
                                                                                                                                   
| Parameter | Description | Type | Default | Required | Hidden |                                                                   
|-----------|-----------|-----------|-----------|-----------|-----------|                                                          
| `skip_subsampling` | Skip sub-sampling with Rasusa | `boolean` |  |  |  |                                                        
| `genome_size` | Genome size for sub-sampling | `string` |  |  |  |                                                               
| `subsampling_depth_cutoff` | Desired coverage depth when sub-sampling | `integer` | 100 |  |  |                                  
                                                                                                                                   
## Assembly options                                                                                                                
                                                                                                                                   
                                                                                                                                   
                                                                                                                                   
| Parameter | Description | Type | Default | Required | Hidden |                                                                   
|-----------|-----------|-----------|-----------|-----------|-----------|                                                          
| `flye_mode` | Nanopore data type | `string` | --nano-hq |  |  |                                                                  
| `skip_medaka` | Skip polishing with Medaka | `boolean` |  |  |  |                                                                
| `medaka_model` | Medaka model to use | `string` |  |  |  |                                                                       
| `medaka_model_base_path` | Path to Medaka models directory on Github | `string` |                                                https://github.com/nanoporetech/medaka/raw/refs/heads/master/medaka/data/ |  |  |                                                  
| `medaka_model_base_full_path` | Full path to Medaka model including Github and model name | `string` |                           https://github.com/nanoporetech/medaka/raw/refs/heads/master/medaka/data/_model_pt.tar.gz |  |  |                                  
                                                                                                                                   
## Annotation options                                                                                                              
                                                                                                                                   
                                                                                                                                   
                                                                                                                                   
| Parameter | Description | Type | Default | Required | Hidden |                                                                   
|-----------|-----------|-----------|-----------|-----------|-----------|                                                          
| `skip_annotation` | Skip annotation with Bakta | `boolean` |  |  |  |                                                            
| `baktadb` | Path to Bakta database directory | `string` |  |  |  |                                                               
| `proteins` | Fasta file of trusted protein sequences for CDS annotation | `string` |  |  |  |                                    
| `prodigal_tf` | Path to existing Prodigal training file to use for CDS prediction | `string` |  |  |  |                          
| `skip_mlst` | Skip MLST assignment with mlst | `boolean` |  |  |  |                                                              
                                                                                                                                   
## Assembly QC options                                                                                                             
                                                                                                                                   
                                                                                                                                   
                                                                                                                                   
| Parameter | Description | Type | Default | Required | Hidden |                                                                   
|-----------|-----------|-----------|-----------|-----------|-----------|                                                          
| `skip_assemblyqc` | Skip assembly QC with CheckM2 and QUAST | `boolean` |  |  |  |                                               
| `skip_quast` | Skip assembly QC with QUAST | `boolean` |  |  |  |                                                                
| `checkm2db` | Path to CheckM2 DIAMOND database file | `string` |  |  |  |                                                        
                                                                                                                                   


