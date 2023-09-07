//
// Sub-sampling subworkflow
//

include { MASH_SKETCH      } from '../../modules/nf-core/mash/sketch/main'
include { RASUSA           } from '../../modules/nf-core/rasusa/main'

workflow SUB_SAMPLING {
    take:
    reads // channel: INPUT_CHECK or FASTP

    main:

    ch_versions = Channel.empty()
    
    //If genome size is not defined
    if (params.genome_size) {
        reads_and_genome_size = reads.combine([params.genome_size])
    } else {
        MASH_SKETCH (
            reads
        )
        genome_size           = MASH_SKETCH.out.stats.map { meta, file -> [meta, WorkflowBovisanalyzer.find_genome_size(file.text)]}
        reads_and_genome_size = reads.combine(genome_size, by: 0)
        ch_versions           = ch_versions.mix(MASH_SKETCH.out.versions.first())
    }

    RASUSA (
        reads_and_genome_size,
        params.subsampling_depth_cutoff
    )
    ch_versions = ch_versions.mix(RASUSA.out.versions.first())

    emit:
    reads   = RASUSA.out.reads      // channel: [ reads ]
    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}