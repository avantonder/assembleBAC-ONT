/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryMap         } from 'plugin/nf-validation'
include { paramsSummaryMultiqc     } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText   } from '../subworkflows/local/utils_assemblebacont_pipeline'
include { validateInputSamplesheet } from '../subworkflows/local/utils_assemblebacont_pipeline'
include { validateParameters; paramsHelp; paramsSummaryLog; fromSamplesheet } from 'plugin/nf-validation'

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.baktadb, params.checkm2db,
                           params.multiqc_logo, params.multiqc_methods_description ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if ( params.input ) {
    ch_input = file(params.input, checkIfExists: true)
} else {
    error("Input samplesheet not specified")
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { LONGREAD_PREPROCESSING } from '../subworkflows/local/longread_preprocessing'
include { SUB_SAMPLING           } from '../subworkflows/local/sub_sampling'

include { FLYE_PARSE             } from '../modules/local/flye_parse'
include { CHECKM2                } from '../modules/local/checkm2/main'
include { CHECKM2_PARSE          } from '../modules/local/checkm2_parse'
include { MLST_PARSE             } from '../modules/local/mlst_parse'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CAT_FASTQ as MERGE_RUNS } from '../modules/nf-core/cat/fastq/main'
include { FASTQC                  } from '../modules/nf-core/fastqc/main'
include { FALCO                   } from '../modules/nf-core/falco/main'
include { FLYE                    } from '../modules/nf-core/flye/main'
include { MEDAKA                  } from '../modules/nf-core/medaka/main'
include { MLST                    } from '../modules/nf-core/mlst/main'
include { QUAST                   } from '../modules/nf-core/quast/main'
include { BAKTA_BAKTA             } from '../modules/nf-core/bakta/bakta/main'
include { MULTIQC                 } from '../modules/nf-core/multiqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ASSEMBLEBACONT {

    take:
    samplesheet // channel: samplesheet read in from --input

    main:
    
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
      
    // Validate input file and create channel for FASTQ data
    ch_input = samplesheet
        .map { meta, fastq -> 
        
        // Define single_end
        meta.single_end = ( fastq )
        
        return [ meta, fastq ]
        }
    
    if ( params.perform_runmerging ) {
    
        ch_reads_for_cat = ch_input
            .map { meta, fastq -> [ meta, fastq.flatten() ]
            }
            .branch { meta, fastq -> 
            // we can't concatenate files if there is not a second run, we branch
            // here to separate them out, and mix back in after for efficiency
                cat: ( fastq.size() > 1 )
                skip: true
            }

        ch_reads_runmerged = MERGE_RUNS ( ch_reads_for_cat.cat ).reads
                .mix( ch_reads_for_cat.skip )
                .map {
                    meta, fastq ->
                    [ meta, [ fastq ].flatten() ]
                }

            ch_versions = ch_versions.mix(MERGE_RUNS.out.versions)

    } else {
        ch_reads_runmerged = ch_input
    }
    
    /*
        MODULE: Run FastQC
    */


    if ( !params.skip_preprocessing_qc ) {
        if ( params.preprocessing_qc_tool == 'falco' ) {
            FALCO ( ch_reads_runmerged )
            ch_versions = ch_versions.mix(FALCO.out.versions.first())
        } else {
            FASTQC ( ch_reads_runmerged )
            ch_versions = ch_versions.mix(FASTQC.out.versions.first())
        }
    }
    
    /*
        SUBWORKFLOW: PERFORM PREPROCESSING
    */

    if ( params.perform_longread_qc ) {
        ch_longreads_preprocessed = LONGREAD_PREPROCESSING ( ch_reads_runmerged ).reads
                                        .map { it -> [ it[0], [it[1]] ] }
        ch_versions = ch_versions.mix( LONGREAD_PREPROCESSING.out.versions )
    } else {
        ch_longreads_preprocessed = ch_reads_runmerged
    }

    //
    // MODULE: Subsample reads
    //
    if (!params.skip_subsampling) {
        SUB_SAMPLING(
            ch_longreads_preprocessed
        )
        ch_trimmed_reads = SUB_SAMPLING.out.reads
        ch_versions      = ch_versions.mix(SUB_SAMPLING.out.versions.first())
    } else {
        ch_trimmed_reads = ch_longreads_preprocessed
    }
   
    //
    // MODULE: Run flye
    //
    FLYE (
            ch_trimmed_reads,
            params.flye_mode
        )
    //ch_assemblies_medaka = FLYE.out.fasta
    ch_flye_logs       = FLYE.out.log
    ch_flye_assemblies = FLYE.out.fasta
    ch_versions        = ch_versions.mix(FLYE.out.versions.first())

    // Create channel for Medaka
    ch_trimmed_reads               // tuple val(meta), path(reads)
        .join( FLYE.out.fasta )    // tuple val(meta), path(assembly)
        .set { ch_reads_assembly } // tuple val(meta), path(reads), path(assembly)
    
    //
    // MODULE: Summarise mlst outputs
    //
    FLYE_PARSE (
            ch_flye_logs.collect{it[1]}.ifEmpty([])
        )
    ch_versions = ch_versions.mix(FLYE_PARSE.out.versions.first())
    
    //
    // MODULE: Run Medaka
    //
    if (!params.skip_medaka) {
        MEDAKA (
                ch_reads_assembly,
                params.medaka_model
            )
        ch_assemblies_bakta   = MEDAKA.out.assembly
        ch_assemblies_mlst    = MEDAKA.out.assembly
        ch_assemblies_checkm2 = MEDAKA.out.assembly
        ch_assemblies_quast   = MEDAKA.out.assembly
        ch_versions           = ch_versions.mix(MEDAKA.out.versions.first())
    } else {
        ch_assemblies_bakta   = ch_flye_assemblies
        ch_assemblies_mlst    = ch_flye_assemblies
        ch_assemblies_checkm2 = ch_flye_assemblies
        ch_assemblies_quast   = ch_flye_assemblies
    }

    //
    // MODULE: Run mlst
    //
    if (!params.skip_mlst) {
        MLST (
                ch_assemblies_mlst        
            )
            ch_mlst_mlstparse = MLST.out.tsv
            ch_versions = ch_versions.mix(MLST.out.versions.first())

        //
        // MODULE: Summarise mlst outputs
        //
        MLST_PARSE (
                ch_mlst_mlstparse.collect{it[1]}.ifEmpty([])
            )
            ch_versions = ch_versions.mix(MLST_PARSE.out.versions.first())
    }

    //
    // MODULE: Run bakta
    //
    ch_baktadb = Channel.empty()

    if (!params.skip_annotation) {
        ch_baktadb = file(params.baktadb)
        
        BAKTA_BAKTA (
                ch_assemblies_bakta,
                ch_baktadb,
                [],
                []           
            )
            ch_versions = ch_versions.mix(BAKTA_BAKTA.out.versions.first())
    }

    ch_checkm2db = Channel.empty()
    
    if (!params.skip_assemblyqc) {
        ch_checkm2db = file(params.checkm2db)
        //
        // MODULE: Run checkm2
        //
        CHECKM2 (
                ch_assemblies_checkm2,
                ch_checkm2db          
            )
            ch_checkm2_checkm2parse = CHECKM2.out.tsv
            ch_versions = ch_versions.mix(CHECKM2.out.versions.first())

        //
        // MODULE: Summarise checkm2 outputs
        //
        CHECKM2_PARSE (
                ch_checkm2_checkm2parse.collect{it[1]}.ifEmpty([])
            )
            ch_versions = ch_versions.mix(CHECKM2_PARSE.out.versions.first())

        //
        // MODULE: Run quast
        //
        if (!params.skip_quast) {
            ch_assemblies_quast
                .map { meta, fasta -> fasta }
                .collect()
                .set { ch_to_quast }
            
            QUAST (
                    ch_to_quast,
                    [],
                    []
                )
                ch_versions = ch_versions.mix(QUAST.out.versions.first())
        }
    }
    
    /*
        MODULE: MultiQC
    */

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'taxprofiler_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.fromPath("${workflow.projectDir}/docs/images/assemblebacont_logo.png", checkIfExists: true)

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    if ( !params.skip_preprocessing_qc ) {
        if ( params.preprocessing_qc_tool == 'falco' ) {
            // only mix in files actually used by MultiQC
            ch_multiqc_files = ch_multiqc_files.mix(FALCO.out.txt
                                .map { meta, reports -> reports }
                                .flatten()
                                .filter { path -> path.name.endsWith('_data.txt')}
                                .ifEmpty([]))
        } else {
            ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
        }
    }

    if (params.perform_longread_qc) {
        ch_multiqc_files = ch_multiqc_files.mix( LONGREAD_PREPROCESSING.out.mqc.collect{it[1]}.ifEmpty([]) )
    }

    if (!params.skip_quast) {
        ch_multiqc_files = ch_multiqc_files.mix(QUAST.out.tsv.collect())
    }

    if (!params.skip_annotation) {
        ch_multiqc_files = ch_multiqc_files.mix(BAKTA_BAKTA.out.txt.collect{it[1]}.ifEmpty([]))
    }

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
