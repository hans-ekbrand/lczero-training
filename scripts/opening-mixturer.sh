#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 total_lines p1 p2 file1.txt file2.txt file3.txt"
    echo "p1 is the proportion of lines taken from file1.txt"
    echo "p2 is the proportion of lines taken from file2.txt"
    echo "1 - p1 - p2 is the proportion of lines taken from file3.txt"
    exit 1
fi

# Read input parameters
total_lines=$1
p1=$2
p2=$3
## The input files is in PGN format, extract only the vital part of each "game" before sampling lines.
grep FEN $4 > temp.file.1
grep FEN $5 > temp.file.2
grep FEN $6 > temp.file.3

file1=temp.file.1
file2=temp.file.2
file3=temp.file.3

# Calculate the number of lines to sample from each file
sample1=$(echo "$total_lines * $p1" | bc | awk '{print int($1+0.5)}')
sample2=$(echo "$total_lines * $p2" | bc | awk '{print int($1+0.5)}')
sample3=$(echo "$total_lines - $sample1 - $sample2" | bc)

# Sample lines from each file and combine them using pipes, back into pgn format
{ shuf -n "$sample1" "$file1"; shuf -n "$sample2" "$file2"; shuf -n "$sample3" "$file3"; } | shuf | awk '{ print $0; print "*\n" }'

rm temp.file.1 temp.file.2 temp.file.3

