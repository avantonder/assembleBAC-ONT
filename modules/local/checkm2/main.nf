process CHECKM2 {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::checkm2=1.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/checkm2:1.0.1--pyh7cba7a3_0' :
        'quay.io/biocontainers/checkm2:1.0.1--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(fasta)
    path db

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    checkm2 predict \\
        --threads $task.cpus \\
        -x '_contigs.fa' \\
        --input $fasta \\
        --database_path $db \\
        --output-directory $prefix
    mv ${prefix}/quality_report.tsv ${prefix}_quality_report.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: \$( echo \$(checkm2 --version 2>&1) )
    END_VERSIONS
    """

}