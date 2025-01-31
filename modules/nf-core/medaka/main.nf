process MEDAKA {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::medaka=2.0.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/2.0.1--py38h8774169_0' :
        'biocontainers/medaka:2.0.1--py38h8774169_0' }"

    input:
    tuple val(meta), path(reads), path(assembly)
    val model

    output:
    tuple val(meta), path("*.fa.gz"), emit: assembly
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def model = model ? "-m $model" : ""
    """
    medaka_consensus \\
        $model \\
        -t $task.cpus \\
        $args \\
        -i $reads \\
        -d $assembly \\
        -o ./

    mv consensus.fasta ${prefix}.fa

    gzip -n ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
