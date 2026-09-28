library(bambu)

ns <- asNamespace("bambu")
f <- get("makeUnsplicedTibble", envir = ns)
code <- paste(deparse(body(f)), collapse = "\n")

code <- sub("maxTxScore = txScore,", "maxTxScore = max(txScore),",
            code, fixed = TRUE)
code <- sub("maxTxScore.noFit = txScore.noFit,",
            "maxTxScore.noFit = max(txScore.noFit),",
            code, fixed = TRUE)
code <- sub("NSampleTxScore = sum(maxTxScore >",
            "NSampleTxScore = sum(txScore >",
            code, fixed = TRUE)

body(f) <- parse(text = code)[[1]]
unlockBinding("makeUnsplicedTibble", ns)
assign("makeUnsplicedTibble", f, envir = ns)
lockBinding("makeUnsplicedTibble", ns)

# Correct Bambu's no-annotation check.
g <- get("filterTranscriptsByAnnotation", envir = ns)
code <- paste(deparse(body(g)), collapse = "\n")
old <- "sum(filterSet == 0) & length(annotationGrangesList)"
stopifnot(grepl(old, code, fixed = TRUE))
code <- sub(old, "sum(filterSet) == 0 & length(annotationGrangesList)",
            code, fixed = TRUE)
body(g) <- parse(text = code)[[1]]
unlockBinding("filterTranscriptsByAnnotation", ns)
assign("filterTranscriptsByAnnotation", g, envir = ns)
lockBinding("filterTranscriptsByAnnotation", ns)
