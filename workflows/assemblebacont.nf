/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

WorkflowAssemblebacont.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK   } from '../subworkflows/local/input_check'
include { SUB_SAMPLING  } from '../subworkflows/local/sub_sampling'

include { FLYE_PARSE    } from '../modules/local/flye_parse'
include { CHECKM2       } from '../modules/local/checkm2/main'
include { CHECKM2_PARSE } from '../modules/local/checkm2_parse'
include { MLST_PARSE    } from '../modules/local/mlst_parse'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { ARTIC_GUPPYPLEX             } from '../modules/nf-core/artic/guppyplex/main'
include { FILTLONG                    } from '../modules/nf-core/filtlong/main'
include { PORECHOP_PORECHOP           } from '../modules/nf-core/porechop/porechop/main'
include { FLYE                        } from '../modules/nf-core/flye/main'
include { MEDAKA                      } from '../modules/nf-core/medaka/main'
include { MLST                        } from '../modules/nf-core/mlst/main'
include { QUAST                       } from '../modules/nf-core/quast/main'
include { BAKTA_BAKTA                 } from '../modules/nf-core/bakta/bakta/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow ASSEMBLEBACONT {

    ch_versions = Channel.empty()

    // Prepare input from barcode directory specified with --fastq_dir flag

    barcode_dirs = file("${params.fastq_dir}/barcode*", type: 'dir' , maxdepth: 1)

    Channel
            .fromPath( barcode_dirs )
            .filter( ~/.*barcode[0-9]{1,4}$/ )
            .map { dir ->
                def count = 0
                for (x in dir.listFiles()) {
                    if (x.isFile() && x.toString().contains('.fastq')) {
                        count += x.countFastq()
                    }
                }
                return [ dir.baseName , dir, count ]
            }
            .set { ch_fastq_dirs }
    
    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        file(params.input)
    )
    .sample_info
    .join(ch_fastq_dirs, remainder: true)
    .map { barcode, sample, dir, count -> [ [ id: sample, barcode:barcode ], dir ] }
    .set { ch_fastq_dirs }
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    
    //
    // MODULE: Run Artic Guppyplex
    //
    ARTIC_GUPPYPLEX (
        ch_fastq_dirs
    )
    ch_versions = ch_versions.mix(ARTIC_GUPPYPLEX.out.versions.first())
    
    //
    // MODULE: Run filtlong
    //
    FILTLONG (
        ARTIC_GUPPYPLEX.out.fastq,
        params.min_read_length
    )
    ch_filtered_reads = FILTLONG.out.reads
    ch_versions       = ch_versions.mix(FILTLONG.out.versions.first())

    //
    // MODULE: Subsample reads
    //
    if (!params.skip_subsampling) {
        SUB_SAMPLING(
            ch_filtered_reads
        )
        ch_filtered_reads = SUB_SAMPLING.out.reads
        ch_versions       = ch_versions.mix(SUB_SAMPLING.out.versions.first())
    }

    //
    // MODULE: Run porechop
    //
    PORECHOP_PORECHOP (
        ch_filtered_reads
    )
    ch_trimmed_reads = PORECHOP_PORECHOP.out.reads
    ch_versions      = ch_versions.mix(PORECHOP_PORECHOP.out.versions.first())
    
    //
    // MODULE: Run flye
    //
    FLYE (
            ch_trimmed_reads,
            params.flye_mode
        )
    //ch_assemblies_medaka = FLYE.out.fasta
    ch_flye_logs = FLYE.out.log
    ch_versions  = ch_versions.mix(FLYE.out.versions.first())

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
    MEDAKA (
            ch_reads_assembly,
            params.medaka_model
        )
    ch_assemblies_bakta   = MEDAKA.out.assembly
    ch_assemblies_mlst    = MEDAKA.out.assembly
    ch_assemblies_checkm2 = MEDAKA.out.assembly
    ch_assemblies_quast   = MEDAKA.out.assembly
    ch_versions           = ch_versions.mix(MEDAKA.out.versions.first())

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
    }
    //
    // MODULE: Run quast
    //
    ch_assemblies_quast
        .map { meta, fasta -> fasta }
        .collect()
        .set { ch_to_quast }
    
    QUAST (
            ch_to_quast,
            [],
            [],
            false,
            false
        )
        ch_versions = ch_versions.mix(QUAST.out.versions.first())

    //
    // MODULE: Collate software versions
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowAssemblebacont.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowAssemblebacont.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FILTLONG.out.log.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(PORECHOP_PORECHOP.out.log.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(QUAST.out.tsv.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
