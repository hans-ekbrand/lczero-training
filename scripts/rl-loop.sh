#!/bin/bash

export variant=r-mobility
export TF_USE_LEGACY_KERAS=1

## Do 10 iterations.
for i in {1..10} ; do
    echo "Iteration $i"
    bash ~/src/lczero-training/scripts/run-selfplay-at-client.sh &    
    ~/src/lc0/build/release/lc0 selfplay -w `ls -t ~/r-mobility-synthetic/*swa*.gz | head -n1` --openings-pgn=/home/hans/opening-book.pgn --training --games=-2 --parallelism=64 --minibatch-size=16 --visits=2 --sticky-endgames --gaviotatb-paths=/home/hans/gaviota --temperature=0 --temp-ends=14 --temp-ends-t=14 --openings-mode=shuffled --task-workers=0 --policy-softmax-temp=1.45 --resign-wdlstyle=true --noise-epsilon=0.1 --noise-alpha=0.12 --sticky-endgames=true --moves-left-max-effect=0.2 --moves-left-threshold=0.0 --moves-left-slope=0.007 --moves-left-quadratic-factor=0.85 --moves-left-scaled-factor=0.15 --moves-left-constant-factor=0.0 &> result.log
    bash ~/src/lczero-training/scripts/batch-rescore.sh
    python3 $HOME/src/lczero-training/tf/train.py --cfg $HOME/src/lczero-training/tf/configs/${variant}.yaml --output $HOME/leela-nets/${variant}/${i}.gz;
    bash ~/src/lczero-training/scripts/bookmaker.sh
done

