#!/bin/bash

## Run a chunk of lichess puzzle csv

# Check if the input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

# Transform the data
while IFS=',' read -r id fen moves rest; do
    echo "[FEN \"$fen\"]"
    echo "${moves%% *} *"
    echo
done < "$input_file"
