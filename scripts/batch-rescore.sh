#!/bin/bash

bash ~/src/lczero-training/scripts/unique-ify-by-folder-name-outer.sh
for i in /home/hans/leela-training-games/lc0/*; do
    echo ${i};
    rmdir --ignore-fail-on-non-empty ${i};
    ~/src/lc0/build/release/rescorer rescore -t 4 --input=${i} --output=/home/hans/leela-training-games/rescored_synthetic_pool --gaviotatb-paths=/home/hans/gaviota --syzygy-paths=/home/hans/syzygy;
done
