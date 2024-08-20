#!/bin/bash

## move obsolete files in target
find ~/leela-training-games/rescored_synthetic_pool/ -type f -name '*gz' -exec mv {} ~/leela-training-games/rescored_synthetic_pool.archive \;

## avoid duplicate file names
bash ~/src/lczero-training/scripts/unique-ify-by-folder-name-outer.sh

for i in /home/hans/leela-training-games/lc0/*; do
    echo ${i};
    ## remove old empty folders
    rmdir --ignore-fail-on-non-empty ${i};
    ## rescore
    ~/src/lc0/build/release/rescorer rescore -t $(nproc --all) --input=${i} --output=/home/hans/leela-training-games/rescored_synthetic_pool --gaviotatb-paths=/home/hans/gaviota --syzygy-paths=/home/hans/syzygy;
done

## remove the obsolete list of chunks
rm ~/leela-training-games/rescored_synthetic_pool/chunknames.pkl
