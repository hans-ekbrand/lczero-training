#!/bin/bash

## prerequisites to run this script
# 1. a lc0 recent official binary in ~/src/lc0/build/release/lc0
# 2. the lczero-training repo available in ~/src (clone/fork from git@github.com:hans-ekbrand/lczero-training.git)
# 3. a file foo.yaml in ~/src/lczero-training/tf/configs/ for this particular experiment (if the variant is "foo")

## How to run this script
## If the yaml-file is called: vanilla.yaml
## bash run.sh vanilla 1
## will use a binary called lc0_vanilla to create training data and a rescorer called rescorer_vanilla to rescore

## bash run.sh r-mobility 1
## will use a binary called lc0_r-mobility to create training data and a rescorer called rescorer_r-mobility to rescore
## I have branches for the rescorers.

path_to_syzygy="/home/hans/syzygy"

## name for this experiment
variant=$1

mkdir -p ~/leela-training-games/${variant}

export XDG_CACHE_HOME=$HOME/leela-training-games/${variant}

if [[  -z $2 ]]; then
    echo "Required parameter counter missing. To start over use 1"
    exit 0
else
    ## counter to keep track of the number of the current net, so we can restart the process without overwriting existing nets.
    i=$2
fi

## where are the nets stored?
net_dir=$HOME/leela-nets/${variant}
mkdir -p $net_dir

## to avoid overfitting, note that every step consumes batch_size
## number of positions, so 100 steps * batch_size 512 consumes 51.200
## positions. TODO: implement a window mechanism, so that games can be reused.

number_of_games_per_net=2000

max_number_of_visits=800

until false # run this loop until further notice

  ## Generate training data
  do
  ## which net is the current net (used for the game generation), this command find the latest modified file.
  latest_net=`ls -Str ${net_dir} | tail -n 1`
  if [[ -z $latest_net ]]; then
      ## No net available yet, these games are cheap so do many
      $HOME/src/lc0/build/release/lc0_${variant} selfplay --training --games=10000 --parallelism=12 --visits=10 --backend=random
  else
      # Use the latest net
      number_of_visits=$(( max_number_of_visits < i*10 ? max_number_of_visits : i*10 ))
      $HOME/src/lc0/build/release/lc0_${variant} selfplay -w ${net_dir}/${latest_net} --training --games=$number_of_games_per_net --visits=${number_of_visits};
  fi

  ## Rescore
  full_current_dir=`ls -Strd ${XDG_CACHE_HOME}/lc0/data* | tail -n 1`
  current_dir=`basename $full_current_dir`
  output_dir=$HOME/leela-training-games/${variant}-rescored
  ## output_dir=${XDG_CACHE_HOME}/rescored/${current_dir}
  mkdir -p ${output_dir}

  $HOME/src/lc0/build/release/rescorer_${variant} rescore -t 6 --syzygy-paths=$path_to_syzygy --input=${XDG_CACHE_HOME}/lc0/${current_dir} --output=${output_dir}
  ## --input=$HOME/.cache/lc0/${dir_name} --output=$HOME/leela-trainingdata/r-mobility-rescored 

  ## $HOME/src/lc0/build/release/rescorer rescore --syzygy-paths=/home/hans/syzygy --threads=2 --input=${XDG_CACHE_HOME}/lc0/${current_dir} --output=${output_dir} --no-rescore
  rmdir ${full_current_dir}

  ## Train
  ## If the training server is not the local computer, make sure it
  ## has (sshfs) access to the directory where the client drops the
  ## training data. This dir is configured in the yaml file
  export TF_USE_LEGACY_KERAS=1
  python3 $HOME/src/lczero-training/tf/train.py --cfg $HOME/src/lczero-training/tf/configs/${variant}.yaml --output $HOME/leela-nets/${variant}/${i}.gz;

  ## Remove the oldest $number_of_games_per_net games from the training window if the window is larger than some threshold or i is low enough so that we know the net is learning very fast.
  ## For now just remove everything
  rm $HOME/leela-training-games/${variant}-rescored/*

  ((i=i+1))
done
