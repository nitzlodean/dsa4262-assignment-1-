#!/usr/bin/env nextflow

params.reads  = null
params.refFa  = null
params.refGtf = null
params.fix    = null
params.outdir = 'results'
params.mode   = 'annotated'

process MINIMAP2_ALIGN {
    tag "$sample"
    cpus 8
    memory '24 GB'

    input:
    tuple val(sample), path(reads)
    path refFa

    output:
    tuple val(sample), path("${sample}.sam")

    script:
    def flags = sample.contains('directRNA') ?
        '-ax splice -uf -k14' : '-ax splice'
    """
    minimap2 -t ${task.cpus} ${flags} ${refFa} ${reads} > ${sample}.sam
    """
}

process SAM_TO_BAM {
    tag "$sample"
    cpus 2
    memory '4 GB'
    publishDir "${params.outdir}/bam", mode: 'copy'

    input:
    tuple val(sample), path(reads_sam)

    output:
    tuple val(sample), path("${sample}.bam"), path("${sample}.bam.bai")

    script:
    """
    samtools sort -@ ${task.cpus} -m 1G -o ${sample}.bam ${reads_sam}
    samtools index ${sample}.bam
    """
}

process QC {
    tag "$sample"
    cpus 1
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(sample), path(reads_bam), path(reads_bai)

    output:
    path("${sample}.qc.txt")

    script:
    """
    samtools flagstat ${reads_bam} > ${sample}.qc.txt
    echo -n "Primary mapped reads: " >> ${sample}.qc.txt
    samtools view -c -F 0x904 ${reads_bam} >> ${sample}.qc.txt
    """
}

process BAMBU {
    tag "${params.mode}"
    cpus 2
    memory '28 GB'
    publishDir "${params.outdir}/${params.mode}", mode: 'copy'

    input:
    path reads_bam
    path reads_bai
    path refFa
    path refGtf
    path runner
    path fix
    val mode

    output:
    path "counts_transcript.txt"
    path "counts_gene.txt"
    path "extended_annotations.gtf"

    script:
    """
    Rscript ${runner} ${mode} ${refFa} ${refGtf} ${fix} *.bam
    """
}

workflow {
    reads_ch = Channel.fromPath(params.reads, checkIfExists: true)
        .map { read -> tuple(read.name.replaceFirst(/\.fastq\.gz$/, ''), read) }

    fa_ch = Channel.value(file(params.refFa))
    gtf_ch = Channel.value(file(params.refGtf))
    runner_ch = Channel.value(file("${projectDir}/run_bambu.R"))
    fix_ch = Channel.value(file(params.fix))

    MINIMAP2_ALIGN(reads_ch, fa_ch)
    SAM_TO_BAM(MINIMAP2_ALIGN.out)
    QC(SAM_TO_BAM.out)

    bams_ch = SAM_TO_BAM.out
        .map { sample, bam, bai -> bam }
        .collect()

    bais_ch = SAM_TO_BAM.out
        .map { sample, bam, bai -> bai }
        .collect()

    BAMBU(bams_ch, bais_ch, fa_ch, gtf_ch,
          runner_ch, fix_ch, Channel.value(params.mode))
}
