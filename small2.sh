#!/bin/bash

## prerequisites to run this script
# 1. a lc0 recent official binary in ~/src/lc0/build/release/lc0
# 2. the lczero-training repo available in ~/src (clone/fork from git@github.com:hans-ekbrand/lczero-training.git)
# 3. a file foo.yaml in ~/src/lczero-training/tf/configs/ for this particular experiment 

## name for this experiment
variant=small

mkdir -p ~/leela-training-games/${variant}/lc0

export XDG_CACHE_HOME=$HOME/leela-training-games/${variant}

if [[  -z $1 ]]; then
    echo "Required parameter counter missing. To start over use 1"
    exit 0
else
    ## counter to keep track of the number of the current net, so we can restart the process without overwriting existing nets.
    i=$1
fi

## where are the nets stored?
net_dir=$HOME/leela-nets/${variant}
mkdir -p $net_dir

## make sure this is not greater than num_chunks in ${variant}.yaml, or some games will never be used in training.
number_of_games_per_net=$3

until false # run this loop until further notice
  do
  ## which net is the current net (used for the game generation), this command find the latest modified file.
  latest_net=`ls -Str ${net_dir} | tail -n 1`
  if [[ -z $latest_net ]]; then
      ## No net available yet
      $HOME/src/lc0/build/release/lc0 selfplay --training --games=$number_of_games_per_net --parallelism=12 --visits=800 --backend=random
  else
      # generate new training data using the latest net

      ## for multi-gpu setups
      # $HOME/src/lc0/build/release/lc0 selfplay -w ${net_dir}/${latest_net} --training --games=$number_of_games_per_net --backend-opts="(backend=cudnn,gpu=0),(backend=cudnn,gpu=1),(backend=cudnn,gpu=2),(backend=cudnn,gpu=3),(backend=cudnn,gpu=4),(backend=cudnn,gpu=5)" parallelism=12 --visits=10000 --cpuct=1.32 --cpuct-at-root=1.9 --root-has-own-cpuct-params=true --resign-percentage=4.0 --resign-playthrough=20 --temperature=0.9 --temp-endgame=0.30 --temp-cutoff-move=60 --temp-visit-offset=-0.8 --fpu-strategy=reduction --fpu-value=0.23 --fpu-strategy-at-root=absolute --fpu-value-at-root=1.0 --minimum-kldgain-per-node=0.000030 --black.minimum-kldgain-per-node=0.000048 --policy-softmax-temp=1.4 --resign-wdlstyle=true --noise-epsilon=0.1 --noise-alpha=0.12 --sticky-endgames=true --moves-left-max-effect=0.2 --moves-left-threshold=0.0 --moves-left-slope=0.008 --moves-left-quadratic-factor=1.0 --moves-left-constant-factor=0.0;

      ## single GPU
      $HOME/src/lc0/build/release/lc0 selfplay -w ${net_dir}/${latest_net} --training --games=$number_of_games_per_net --visits=10000 --cpuct=1.32 --cpuct-at-root=1.9 --root-has-own-cpuct-params=true --resign-percentage=4.0 --resign-playthrough=20 --temperature=0.9 --temp-endgame=0.30 --temp-cutoff-move=60 --temp-visit-offset=-0.8 --fpu-strategy=reduction --fpu-value=0.23 --fpu-strategy-at-root=absolute --fpu-value-at-root=1.0 --minimum-kldgain-per-node=0.000030 --black.minimum-kldgain-per-node=0.000048 --policy-softmax-temp=1.4 --resign-wdlstyle=true --noise-epsilon=0.1 --noise-alpha=0.12 --sticky-endgames=true --moves-left-max-effect=0.2 --moves-left-threshold=0.0 --moves-left-slope=0.008 --moves-left-quadratic-factor=1.0 --moves-left-constant-factor=0.0;
  fi

  # train a new net
  ## If the training server is not the local computer, make sure it
  ## has (sshfs) access to the directory where the client drops the
  ## training data. This dir is configured in the yaml file
  python3 $HOME/src/lczero-training/tf/train.py --cfg $HOME/src/lczero-training/tf/configs/${variant}.yaml --output $HOME/leela-nets/${variant}/${i}.gz;

  ((i=i+1))
done
