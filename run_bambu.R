args <- commandArgs(trailingOnly = TRUE)
mode <- args[1]
fa.file <- args[2]
gtf.file <- args[3]
fix.file <- args[4]
samples.bam <- args[-(1:4)]

source(fix.file)

if (mode == "annotated") {
  annotations <- prepareAnnotations(gtf.file)
  se <- bambu(reads = samples.bam, annotations = annotations,
              genome = fa.file, ncore = 2)
} else if (mode == "unannotated") {
  se <- bambu(reads = samples.bam, genome = fa.file,
              NDR = 1,
              opt.discovery = list(min.readFractionByEqClass = 0.2),
              ncore = 2)
} else {
  stop("Mode must be annotated or unannotated")
}

writeBambuOutput(se, path = "./")
