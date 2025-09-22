#!/usr/bin/Rscript

# Get the command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the correct number of arguments is provided
if (length(args) < 2) {
  stop("Two arguments must be supplied: number of pieces and delta q", call. = FALSE)
}

number.of.pieces <- as.numeric(args[1])
delta.q <- as.numeric(args[2])
## setwd('/home/hans/mnt/gpu-monster/run-q-from-fens-here/')
## setwd('/home/hans/run-q-from-fens-here/')
## print(paste("Will use", 0.5 + delta.q, 0.5 - delta.q, -0.5 + delta.q, "and", -0.5 - delta.q))

foo <- read.table(paste0('evaluated-', number.of.pieces, "-men-fens.txt"), sep = ",")
these <- which((foo$V2 < 0.5 + delta.q & foo$V2 > 0.5 - delta.q) | (foo$V2 < -0.5 + delta.q & foo$V2 > -0.5 - delta.q))
if(length(args) > 2 & args[3] == "PGN"){
    cat(paste0('[FEN "', foo$V1[these], '"', "]\n*\n\n"), file = paste0("selected-", number.of.pieces, "-men.pgn"), sep = "")
} else {
    cat(foo$V1[these], file = paste0("selected-", number.of.pieces, "-men.epd"), sep = "\n")
}
