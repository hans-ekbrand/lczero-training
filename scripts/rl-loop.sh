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

    # if you want the script to stop based on time of the day (due to varying electricity prices over the course of the day) use the chunk below.
    # Get the current hour (24 hour format)
    current_hour=$(date +%H)

    # Explicitly state the base of the number (otherwise "08" will be interpreted as an illegal octal number.
    current_hour=$((10#$current_hour))

    # Define the target hour (24-hour format)
    target_hour=22    

    # Define the hour to pause the script
    pause_hour=6

    if (( current_hour >= pause_hour )); then
	echo "It's past ${pause_hour}. Pausing the script."
	while true; do
	    current_hour=$(date +%H)
	    current_hour=$((10#$current_hour))  # Explicitly state the base

	    if ((current_hour >= target_hour)); then
		echo "It's ${current_hour}:00. Exiting the wait loop."
		break
	    else
		# Calculate time remaining until the target hour
		hours_remaining=$((target_hour - current_hour))
		echo "It's ${current_hour}:00. Waiting for ${target_hour}:00 (about ${hours_remaining} hours left)..."
		sleep "$((hours_remaining * 3600))"  # Sleep for the remaining hours
	    fi
	done
    else
	echo "It's before ${pause_hour}. Continue the script."
	# Continue with the rest of the script
    fi
    
done

