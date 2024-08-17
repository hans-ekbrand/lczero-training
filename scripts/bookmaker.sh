#!/bin/bash

## collect lines from leela training data
bash ~/merge-pgns.sh
bash ~/merge-different-pgns.sh

## collect lines from random fens that the latest network is unsure about
bash ~/src/lczero-training/scripts/openings-from-random-fens.sh 14 20000 0.2

## sample a mixture from the queues
bash ~/src/lczero-training/scripts/opening-mixturer.sh 20000 0.7 0.1 6-14-men-fens-from-leela-training-data-with-delta_q_0_1.pgn starting_pos.txt ~/run-q-from-fens-here/selected-14-men-fens.pgn > /home/hans/opening-book.pgn

## split the opening book in parts, so that each client only gets unique lines
let lines=`wc opening-book.pgn | awk {'print $1'}`/2
split -l $lines opening-book.pgn
mv xaa ~/mnt/gpu-monster/opening-book.pgn
mv xab ~/opening-book.pgn
