#!/bin/bash

## prerequisites to run this script
# 1. a lc0 recent official binary in ~/src/lc0/build/release/lc0
# 2. the lczero-training repo available in ~/src (clone/fork from git@github.com:hans-ekbrand/lczero-training.git)
# 3. a file foo.yaml in ~/src/lczero-training/tf/configs/ for this particular experiment (call this script with first argument "foo" and second argument = number of games to play.

## name for this experiment
variant=$1

mkdir -p ~/leela-training-games/${variant}/lc0

export XDG_CACHE_HOME=$HOME/leela-training-games/${variant}

## where are the nets stored?
net_dir=$HOME/leela-nets/${variant}
mkdir -p $net_dir

KLD=$2
book=$3

## which net is the current net (used for the game generation), this command finds the latest modified file.
latest_net=`ls -Str ${net_dir} | tail -n 1`
if [[ -z $latest_net ]]; then
    ## No net available yet
    $HOME/src/lc0/build/release/lc0 selfplay --syzygy-paths=/home/hans/syzygy --no-adjudicate --training --training --games=-2 --parallelism=12 --visits=64 --backend=random --openings-pgn=$HOME/${book} --openings-mode=shuffled;
    i=1
else
    # generate new training data using the latest net, and save a new net with +1 to the filename.
    i=`ls -Str ${net_dir} | tail -n 1 | cut -d "." -f 1`
    ((i=i+1))
    $HOME/src/lc0/build/release/lc0 selfplay -w ${net_dir}/${latest_net} --training --games=-2 --syzygy-paths=/home/hans/syzygy --no-adjudicate --visits=10000 --backend-opts="(backend=cudnn,gpu=2)" --cpuct=1.32 --cpuct-at-root=1.9 --root-has-own-cpuct-params=true --resign-percentage=0.0 --resign-playthrough=100 --temperature=0.0 --temp-endgame=0.0 --temp-cutoff-move=60 --temp-visit-offset=0.0 --fpu-strategy=reduction --fpu-value=0.23 --fpu-strategy-at-root=absolute --fpu-value-at-root=1.0 --policy-softmax-temp=1.4 --minimum-kldgain-per-node=$KLD --resign-wdlstyle=true --noise-epsilon=0.1 --noise-alpha=0.12 --sticky-endgames=true --moves-left-max-effect=0.2 --moves-left-threshold=0.0 --moves-left-slope=0.008 --moves-left-quadratic-factor=1.0 --moves-left-constant-factor=0.0 --openings-pgn=${HOME}/${book} --openings-mode=shuffled;
fi

# train a new net
# # tensorflow is installed normally
# python3 $HOME/src/lczero-training/tf/train.py --cfg $HOME/src/lczero-training/tf/configs/${variant}.yaml --output $HOME/leela-nets/${variant}/${i}.gz;

## Run tensorflow in docker, but make sure no one else is already running it, in which case wait for them.
while [[ -a tensorflow.lock ]]; do
    echo `date` "waiting for tensorflow to be free."
    sleep 60;
done
touch tensorflow.lock
docker start 18e24368f7d8
docker exec -it 18e24368f7d8 bash /mnt/src/lczero-training/train_in_docker.sh $i $variant
rm tensorflow.lock
