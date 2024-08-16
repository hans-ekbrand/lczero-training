#!/bin/bash

## openings from random fens
## usage: bash openings-from-random-fens.sh 14 20000 

number_of_pieces=$1
number_of_desired_lines=$2

let number_of_required_intermediate_lines=$2*10

# ## generate
cd ~/src/lczero-training/scripts/
echo "nodejs random-FENs-parent.js $number_of_pieces $number_of_required_intermediate_lines false"
nodejs random-FENs-parent.js $number_of_pieces $number_of_required_intermediate_lines false
mv ${number_of_pieces}-men-fens.pgn ~/run-q-from-fens-here/

## evaluate
cd ~/run-q-from-fens-here/
pwd
## locate the latest net
latest_net=`ls -lStr ~/r-mobility-synthetic/*swa*.gz | tail -n 1 | cut -d " " -f 9`
## works with a symlink, but the file has to have a newer timestamp than any .txt file in that dir.
## which is a reason to let file suffix from generation remain .pgn even it is not a pgn when
## invoked with "false"
if [[ ! -L `basename $latest_net` ]]; then
    rm *.gz ## remove obsolete link
    ln -s $latest_net .
fi
python3 ~/src/lczero-training/scripts/q-from-fens.py -i ${number_of_pieces}-men-fens.pgn > evaluated-${number_of_pieces}-men-fens.txt
ls -lStr
## creates evaluated-${number_of_pieces}-men-fens.txt

## select
Rscript ~/src/lczero-training/scripts/pick-interesting-fens.R $number_of_pieces 0.2
ls -lStr
## creates selected-${number_of_pieces}-men-fens.pgn

## clean up intermediate files
rm evaluated-${number_of_pieces}-men-fens.txt ${number_of_pieces}-men-fens.pgn
ls -lStr

## resulting opening file is now in selected-${number_of_pieces}-men-fens.pgn
