#!/bin/bash

## openings from random fens
## usage: bash openings-from-random-fens.sh 14 20000 0.2

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 number_of_pieces number_of_desired_lines delta_q"
    echo "Usage: $0 14 20000 0.2"    
    exit 1
fi

number_of_pieces=$1
number_of_desired_lines=$2
delta_q=$3 # 0.2 was hardcoded before

let number_of_required_intermediate_lines=$2*15
## the constant 15 might have to be adjusted over time. For now it generates a bit more than the requested lines

# ## generate
cd ~/src/lczero-training/scripts/
nodejs random-FENs-parent.js $number_of_pieces $number_of_required_intermediate_lines false
mv ${number_of_pieces}-men-fens.pgn ~/run-q-from-fens-here/

## evaluate
cd ~/run-q-from-fens-here/
## locate the latest net
latest_net=`ls -t ~/r-mobility-synthetic/*swa*.gz | head -n1`
## works with a symlink, but the file has to have a newer timestamp than any .txt file in that dir.
## which is a reason to let file suffix from generation remain .pgn even it is not a pgn when
## invoked with "false"

rm -rf *.gz ## remove obsolete link
ln -s $latest_net .
## make it the newest file in the folder
touch *.gz

python3 ~/src/lczero-training/scripts/q-from-fens.py -i ${number_of_pieces}-men-fens.pgn > evaluated-${number_of_pieces}-men-fens.txt
## creates evaluated-${number_of_pieces}-men-fens.txt

## select
Rscript ~/src/lczero-training/scripts/pick-interesting-fens.R $number_of_pieces $delta_q
## creates selected-${number_of_pieces}-men-fens.pgn

## clean up intermediate files
rm evaluated-${number_of_pieces}-men-fens.txt ${number_of_pieces}-men-fens.pgn

## resulting opening file is now in selected-${number_of_pieces}-men-fens.pgn
