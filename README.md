# dsa4262-assignment-1-
This is the NextFlow workflow design for DSA4262 Assignment 1 AY 26/27 Sem 1. 

I adapted the existing SG-NEx workshop Nextflow pipeline by Jonathan Göke rather than developing the workflow entirely from scratch. I extended it to process all four samples, select minimap2 settings by sequencing protocol, sort and index the BAM files, add a samtools QC process, and support annotated and unannotated Bambu runs with Nextflow caching. I also added the R runner and compatibility script included in the repository.

# Long-read RNA-seq workflow

This Nextflow workflow processes four SG-NEx human cancer cell line samples. It aligns direct RNA and cDNA reads to GRCh38 with minimap2, sorts and indexes the BAM files with samtools, records alignment QC, and uses Bambu for transcript discovery and quantification.

The workflow supports two Bambu modes:

- **Annotated:** uses a reference GTF.
- **Unannotated:** runs transcript discovery without a reference GTF. Run this mode with `-resume` after the annotated mode to reuse the alignment, BAM conversion, and QC tasks.

## Files

- `workflow_longReadRNASeq.nf` — Nextflow pipeline
- `run_bambu.R` — runs Bambu in the selected mode and exports its results
- `bambu_fix.R` — session-level corrections needed for the Bambu version used in this analysis

## Requirements and inputs

Nextflow, minimap2, samtools, R, and the Bambu R package must be installed. The workflow takes compressed FASTQ files, a GRCh38 reference FASTA, and a GTF file. The GTF is supplied to the workflow in both modes, but Bambu uses it only in annotated mode. The FASTQ filenames must contain `directRNA` or `cDNA` so the appropriate minimap2 settings can be selected.

Run these commands from the directory containing the three code files, replacing the example input paths:

```bash
nextflow run workflow_longReadRNASeq.nf \
  -with-report report_annotated.html \
  --reads "/path/to/fastq/*.fastq.gz" \
  --refFa "/path/to/GRCh38.fa" \
  --refGtf "/path/to/annotations.gtf" \
  --fix "$PWD/bambu_fix.R" \
  --outdir "$PWD/results" \
  --mode annotated
```

```bash
nextflow run workflow_longReadRNASeq.nf \
  -with-report report_unannotated.html \
  -resume \
  --reads "/path/to/fastq/*.fastq.gz" \
  --refFa "/path/to/GRCh38.fa" \
  --refGtf "/path/to/annotations.gtf" \
  --fix "$PWD/bambu_fix.R" \
  --outdir "$PWD/results" \
  --mode unannotated
```

## Outputs and QC

Sorted BAM files and their indices are written to `results/bam/`. Per-sample samtools QC reports are written to `results/qc/`. Bambu writes transcript counts, gene counts, and extended annotations to `results/annotated/` or `results/unannotated/`. Nextflow also generates an HTML execution report for each run.

The QC reports include the number of primary mapped reads. For this assignment, I treated fewer than 10,000 primary mapped reads as insufficient depth; this threshold is applied when interpreting the reports, rather than filtering samples out of the workflow.

## Notes

This pipeline was adapted from the SG-NEx workshop Nextflow example. The Bambu correction script is included so the analysis can be reproduced with the package versions used here. Novel transcripts and low-depth samples should be reviewed further before drawing biological conclusions.
