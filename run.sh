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
proportion_to_remove=0.90

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

until false; do # run this loop until further notice
  ## Generate training data

  ## Create a function to determine the number of new games required for creating a new net
  ## which depends on the iteration number i
  ## At i = 1 the outcome should be 500
  ## at i = 50 the outcome is about 1420
  ## at i = 100 the outcome should be 2000

  ## use arctan which is bounded
  ## Set number of games before creating a new net.
  number_of_games_per_net=$(echo "scale=2; 500 + 2000 * a($i/100)" | bc -l | cut -d "." -f 1)
  echo "At iteration $i producing $number_of_games_per_net games before training a new net"

  ## --minimum-kldgain-per-node=0.000050, --openings-pgn=books/run2_book.pgn.gz, --openings-mode=shuffled, 
  
  ## which net is the current net (used for the game generation), this command find the latest modified file.
  latest_net=`ls -Str ${net_dir} | tail -n 1`
  if [[ -z $latest_net ]]; then
      ## No net available yet, these games are cheap so do many
      $HOME/src/lc0/build/release/lc0_${variant} selfplay --training --games=10000 --parallelism=6 --visits=2 --backend=random --syzygy-paths=$path_to_syzygy
  else
      # Use the latest net
      number_of_visits=$(( max_number_of_visits < i*10 ? max_number_of_visits : i*10 ))
      echo "Using $number_of_visits number of visits per move, and $number_of_games_per_net number of games for iteration $i"
      $HOME/src/lc0/build/release/lc0_${variant} selfplay -w ${net_dir}/${latest_net} --backend-opts=max_batch=256 --training --games=$number_of_games_per_net --parallelism=8 --visits=${number_of_visits} --cpuct=1.32 --cpuct-at-root=2.0 --root-has-own-cpuct-params=true --resign-percentage=2.0 --resign-playthrough=95 --resign-earliest-move=50 --temperature=0.9 --temp-endgame=0.60 --tempdecay-moves=60 --tempdecay-delay-moves=20 --temp-cutoff-move=40 --temp-visit-offset=-0.8 --fpu-strategy=reduction --fpu-value=0.26 --fpu-strategy-at-root=absolute --fpu-value-at-root=1.0 --policy-softmax-temp=1.45 --resign-wdlstyle=true --noise-epsilon=0.1 --noise-alpha=0.12 --sticky-endgames=true --moves-left-max-effect=0.2 --moves-left-threshold=0.0 --moves-left-slope=0.007 --moves-left-quadratic-factor=0.85 --moves-left-scaled-factor=0.15 --moves-left-constant-factor=0.0 --task-workers=0 --syzygy-paths=$path_to_syzygy
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
  if [[ -f ${output_dir}/chunknames.pkl ]]; then
      rm ${output_dir}/chunknames.pkl
  fi
  ## how many games turned out useful as training data?
  total_number_of_training_data_chunks=`ls ${output_dir} | wc | awk {'print $1'}`
  let number_of_new_training_data_chunks=total_number_of_training_data_chunks-number_of_remaining_training_data_chunks
  rmdir ${full_current_dir}

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
	  total_files=$(ls ${output_dir} | wc | awk {'print $1'})

	  # Calculate the number of files to keep
	  files_to_keep=$(($total_files-$games_to_remove))

	  echo "`date "+%Y-%m-%d %H:%M:%S"` Number of remaining training data chunks from the previous iteration: ${number_of_remaining_training_data_chunks}. Number of new training games: ${number_of_new_training_games}, number of new training data chunks: ${number_of_new_training_data_chunks}. Number of games to remove (should be equal to number_of_new_training_data_chunks * 0.75): ${games_to_remove}. Total Number of training data chunks before deletions: ${total_files}. Target number of files after deletion: ${files_to_keep}."
	  # echo "oldest training data chunk is dated: `ls -lSt  --time-style=full-iso $HOME/leela-training-games/${variant}-rescored | tail -n 1`"
	  # echo "youngest training data chunk is dated: `ls -lSt --time-style=full-iso $HOME/leela-training-games/${variant}-rescored | head -n 2 | tail -n 1`"
	  # echo "yongest training data to delete: `ls -lSt  --time-style=full-iso $HOME/leela-training-games/${variant}-rescored | tail -n +$(($files_to_keep)) | head -n 1`"
	  # echo "oldest training data to keep: `ls -lSt  --time-style=full-iso $HOME/leela-training-games/${variant}-rescored | tail -n +$(($files_to_keep + 1)) | head -n 1`"

	  # Delete the oldest files
	  ls -t $output_dir | tail -n $games_to_remove | xargs -I {} rm $output_dir/{} ;
	  # echo "verify that the right files where deleted, oldest remaining file is: `ls -lSt  --time-style=full-iso $HOME/leela-training-games/${variant}-rescored | tail -n $(($games_to_remove-1)) | head -n 1` and youngest remaining file is `ls -lSt --time-style=full-iso $HOME/leela-training-games/${variant}-rescored | head -n 2 | tail -n 1`"
	  new_total_files=$(ls ${output_dir} | wc | awk {'print $1'})
	  echo "number of files added by this iteration: $(($new_total_files-${number_of_remaining_training_data_chunks}))"
	  echo "number of files remaining after this iteration: $(($new_total_files))"
      fi
  fi

  ## if you want the script to stop based on time of the day (due to varying electricity prices over the course of the day) use the chunk below.
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
