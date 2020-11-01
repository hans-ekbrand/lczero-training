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

## $book is the source for the dynamically generated books actually used in training.
actual_book=${variant}_actual_book.pgn

## calculate $i
latest_net=`ls -Str ${net_dir} | tail -n 1`
if [[ -z $latest_net ]]; then
    ## No net available yet
    i=1
else
    i=`ls -Str ${net_dir} | tail -n 1 | cut -d "." -f 1`
    ((i=i+1))
fi

## use $i to create an opening book

## generate a new version of the opening book.
let lines_per_book=${4}*4 ## one game occupies four lines
let ending_line_of_new_chunk=i*lines_per_book+${5}
max_of_current_book=`wc ${HOME}/${book} | mawk {'print $1'}`
## echo "max of current book: $max_of_current_book, want to end at $ending_line_of_new_chunk"
## if this is outside the current book, then restart from the remainder number of rows
if [[ ending_line_of_new_chunk -gt max_of_current_book ]]; then
    let ending_line_of_new_chunk=$((ending_line_of_new_chunk % max_of_current_book))
    if [[ ending_line_of_new_chunk -lt lines_per_book ]]; then
       let ending_line_of_new_chunk=ending_line_of_new_chunk+lines_per_book;
    fi
    ## echo "new chunk ending: $ending_line_of_new_chunk"
fi
echo "Generating a new temporary opening book ${actual_book} based on ${book} with ${4} positions, ending at position ${ending_line_of_new_chunk}";
head -n $ending_line_of_new_chunk ${HOME}/${book} | tail -n $lines_per_book > ${HOME}/$actual_book

if [[ -z $latest_net ]]; then
    ## No net available yet
    $HOME/src/lc0/build/release/lc0 selfplay --syzygy-paths=/home/hans/syzygy --no-adjudicate --training --games=-2 --parallelism=32 --visits=800 --backend=random --openings-pgn=$HOME/${actual_book} --openings-mode=sequential;
else
    # generate new training data using the latest net, and save a new net with +1 to the filename.
   $HOME/src/lc0/build/release/lc0 selfplay -w ${net_dir}/${latest_net} --training --games=-2 --syzygy-paths=/home/hans/syzygy --no-adjudicate --visits=10000  --backend-opts="(backend=cudnn,gpu=0),(backend=cudnn,gpu=1),(backend=cudnn,gpu=2),(backend=cudnn,gpu=3),(backend=cudnn,gpu=4),(backend=cudnn,gpu=5)" --parallelism=12 --cpuct=1.32 --cpuct-at-root=1.9 --root-has-own-cpuct-params=true --resign-percentage=0.0 --resign-playthrough=100 --temperature=0.0 --temp-endgame=0.0 --temp-cutoff-move=60 --temp-visit-offset=0.0 --fpu-strategy=reduction --fpu-value=0.23 --fpu-strategy-at-root=absolute --fpu-value-at-root=1.0 --policy-softmax-temp=1.4 --minimum-kldgain-per-node=$KLD --resign-wdlstyle=true --noise-epsilon=0.1 --noise-alpha=0.12 --sticky-endgames=true --moves-left-max-effect=0.2 --moves-left-threshold=0.0 --moves-left-slope=0.008 --moves-left-quadratic-factor=1.0 --moves-left-constant-factor=0.0 --openings-pgn=${HOME}/${actual_book} --openings-mode=sequential;
fi

# rescore
## find the current directory
full_current_dir=`ls -Strd ${XDG_CACHE_HOME}/lc0/data* | tail -n 1`
current_dir=`basename $full_current_dir`
output_dir=${XDG_CACHE_HOME}/rescored/${current_dir}
mkdir -p ${output_dir}
$HOME/src/lc0/build/release/rescorer rescore --syzygy-paths=/home/hans/syzygy --threads=2 --input=${XDG_CACHE_HOME}/lc0/${current_dir} --output=${output_dir} --no-rescore
rmdir ${full_current_dir}

# train a new net
# If tensorflow is to be run in docker, place a file `.tensorflow_runs_in_docker` in $HOME and adjust the docker id below, and edit the script `train_in_docker.sh` to fit your settings.

# But first, make sure no one else is already running tensorflow, in which case wait for them.
while [[ -a tensorflow.lock ]]; do
    echo `date` "waiting for tensorflow to be free."
    sleep 60;
done
touch tensorflow.lock

if [[ -a $HOME/.tensorflow_runs_in_docker ]] ; then
    ## Run tensorflow in docker.
    docker start 18e24368f7d8
    docker exec -it 18e24368f7d8 bash /mnt/src/lczero-training/train_in_docker.sh $i $variant
    rm tensorflow.lock
else
    # tensorflow is installed normally
    python3 $HOME/src/lczero-training/tf/train.py --cfg $HOME/src/lczero-training/tf/configs/${variant}.yaml --output $HOME/leela-nets/${variant}/${i}.gz;
    rm tensorflow.lock
fi
