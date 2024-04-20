#!/bin/bash

## prerequisites to run this script
# 1. a lc0 recent official binary in ~/src/lc0/build/release/lc0
# 2. the lczero-training repo available in ~/src (clone/fork from git@github.com:hans-ekbrand/lczero-training.git)
# 3. a file foo.yaml in ~/src/lczero-training/tf/configs/ for this particular experiment (if the variant is "foo")

## to remove old stuff for a variant called "vanilla" run
## rm -rf $HOME/leela-nets/vanilla/ $HOME/leelalogs/vanilla-* $HOME/leela-training-games/vanilla* $HOME/vanilla
## rm -rf $HOME/leela-nets/r-mobility/ $HOME/leelalogs/r-mobility-* $HOME/leela-training-games/r-mobility* $HOME/r-mobility

## How to run this script
## If the yaml-file is called: vanilla.yaml
## bash run.sh vanilla 1
## will use a binary called lc0_vanilla to create training data and a rescorer called rescorer_vanilla to rescore

## bash run.sh r-mobility 1
## will use a binary called lc0_r-mobility to create training data and a rescorer called rescorer_r-mobility to rescore
## I have branches for the rescorers.

## keep a small proportion of training data to increase the window of training data games
proportion_to_remove=0.75

## Set number of games before creating a new net.
number_of_games_per_net=500

## Number of steps per net is defined in the yaml-file.

## Early on, the number of visits will be lower, reaching the max after 80 iterations.
max_number_of_visits=800

path_to_syzygy="/home/hans/syzygy"

## name for this experiment
variant=$1

mkdir -p ~/leela-training-games/${variant}

export XDG_CACHE_HOME=$HOME/leela-training-games/${variant}

if [[  -z $2 ]]; then
    echo "`date "+%Y-%m-%d %H:%M:%S"` Required parameter counter missing. To start over use 1"
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
## positions.

until false # run this loop until further notice

  ## Generate training data
  do
  ## which net is the current net (used for the game generation), this command find the latest modified file.
  latest_net=`ls -Str ${net_dir} | tail -n 1`
  if [[ -z $latest_net ]]; then
      ## No net available yet, these games are cheap so do many
      $HOME/src/lc0/build/release/lc0_${variant} selfplay --training --games=1000 --parallelism=12 --visits=2 --backend=random
  else
      # Use the latest net
      number_of_visits=$(( max_number_of_visits < i*10 ? max_number_of_visits : i*10 ))
      $HOME/src/lc0/build/release/lc0_${variant} selfplay -w ${net_dir}/${latest_net} --backend-opts=max_batch=256 --training --games=$number_of_games_per_net --visits=${number_of_visits};
  fi

  ## Rescore
  full_current_dir=`ls -Strd ${XDG_CACHE_HOME}/lc0/data* | tail -n 1`
  current_dir=`basename $full_current_dir`
  output_dir=$HOME/leela-training-games/${variant}-rescored
  mkdir -p ${output_dir}

  number_of_remaining_training_data_chunks=`ls ${output_dir} | wc | awk {'print $1'}`
  number_of_new_training_games=`ls ${XDG_CACHE_HOME}/lc0/${current_dir} | wc | awk {'print $1'}`

  ## rename the new games so that they will have unique filename and not be overwritten in the next iteration
  rename -d "s/\.gz/_${current_dir}\.gz/" ${XDG_CACHE_HOME}/lc0/${current_dir}/*gz
  
  $HOME/src/lc0/build/release/rescorer_${variant} rescore -t `nproc --all` --syzygy-paths=$path_to_syzygy --input=${XDG_CACHE_HOME}/lc0/${current_dir} --output=${output_dir}
  ## Since we want to train on both new and remaining chunks, dont use the manifest file which (I assume) only include the new chunks.
  if [[ -f $HOME/leela-training-games/${variant}-rescored/chunknames.pkl ]]; then
      rm $HOME/leela-training-games/${variant}-rescored/chunknames.pkl
  fi
  ## how many games turned out useful as training data?
  total_number_of_training_data_chunks=`ls ${output_dir} | wc | awk {'print $1'}`
  let number_of_new_training_data_chunks=total_number_of_training_data_chunks-number_of_remaining_training_data_chunks
  rmdir ${full_current_dir}
  echo "`date "+%Y-%m-%d %H:%M:%S"` Number of remaining training data chunks from the previous iteration: ${number_of_remaining_training_data_chunks}. Number of new training games: ${number_of_new_training_games}, number of new training data chunks: ${number_of_new_training_data_chunks}."
  echo "oldest training data chunk is dated: `ls -lSt $HOME/leela-training-games/${variant}-rescored | tail -n 1`"

  ## Train
  ## If the training server is not the local computer, make sure it
  ## has (sshfs) access to the directory where the client drops the
  ## training data. This dir is configured in the yaml file
  export TF_USE_LEGACY_KERAS=1
  echo "`date "+%Y-%m-%d %H:%M:%S"` Starting training iteration ${i} (generating net named ${i}.gz)"
  python3 $HOME/src/lczero-training/tf/train.py --cfg $HOME/src/lczero-training/tf/configs/${variant}.yaml --output $HOME/leela-nets/${variant}/${i}.gz;

  ## if we have passed the first iteration then only remove a proportion of the oldest games from the training window.
  if [[ -z $latest_net ]]; then
      rm $HOME/leela-training-games/${variant}-rescored/*
  else
      # Calculate the product and round the result to 
      games_to_remove=$(echo "scale=0; ($number_of_new_training_data_chunks * $proportion_to_remove + 0.5)/1" | bc)
      if [[ $games_to_remove -gt 0 ]]; then
	  # Get the total number of files in the directory
	  total_files=$(ls -1 $HOME/leela-training-games/${variant}-rescored | wc -l)

	  # Calculate the number of files to keep
	  files_to_keep=$(($total_files-$games_to_remove))

	  # Delete some files
	  echo "`date "+%Y-%m-%d %H:%M:%S"` Deleting the ${games_to_remove} oldest rescored files, keeping ${files_to_keep} files. Youngest file to delete is "
	  echo "`ls -lSt $HOME/leela-training-games/${variant}-rescored | tail -n 1`"
	  echo "Oldest file to delete is `ls -lSt $HOME/leela-training-games/${variant}-rescored | tail -n +$(($games_to_remove)) | | tail -n 1`"
	  echo "Oldest file to keep is `ls -lSt $HOME/leela-training-games/${variant}-rescored | tail -n +$(($games_to_remove)) | | head -n 1`"	  
	  ls -t $HOME/leela-training-games/${variant}-rescored | tail -n +$(($games_to_remove)) | xargs -I {} rm -- "$HOME/leela-training-games/${variant}-rescored/{}"
      fi
  fi

  # # Get the current hour (24 hour format)
  # current_hour=$(date +%H)

  # # Define the hour to exit the script
  # exit_hour=7

  # if (( current_hour >= exit_hour )); then
  #     echo "It's past ${exit_hour}. Exiting the script."
  #     exit 0
  # else
  #     echo "It's before ${exit_hour}. Continue the script."
  #     # Continue with the rest of the script
  # fi

  ((i=i+1))
done
