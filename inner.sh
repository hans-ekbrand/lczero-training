## fully automated reinforcement training with varying number of games per net, number of chunks per net, number of steps per net.
## requires an opening book
## 
##            $1     $2             $3              $4         $5     $6    $7    $8
## ./inner.sh turbo2 $HOME          turbo2-book.png 800        16000  250   0.25  25
##            name   home_directory opening book    target_NPM chunks steps lr    total iterations

## for a quick test
## ./inner.sh turbo2 /mnt          turbo2-book.png 100        400  25   0.25  3

## sudo rm -rf ~/kb1-64x6-turbo2/ ~/leelalogs/kb1-64x6-turbo2-t*
## rm -rf ~/leela-nets/turbo2/ ~/leela-training-games/turbo2/ 

## ./outer-turbo.sh turbo /mnt 100 25 0.5 100 800 25 0.5 400

## Set up a yaml-file

initial_KLD=0.0000015

echo "variant=$1
home=$2
chunks=$3
steps=$4
lr=$5" > config.1

./fill.sh config.1 tf/configs/template.yaml tf/configs/${1}.yaml

./single_run_train_in_docker_turbo2.sh $1 $6

echo "variant=$1
home=$2
chunks=$7
steps=$8
lr=$9" > config.2

./fill.sh config.2 tf/configs/template-docker.yaml tf/configs/${1}.yaml

KLD=$initial_KLD
TARGET_NPM=${10}
for i in {1..25}; do
    ./single_run_train_in_docker_turbo2.sh $1 ${KLD}
    ## find out the average NPM previous run
    NPM=`grep "final " ~/turbo2.log | tail -n 1 | cut -d " " -f 23`
    scale=`bc -l <<< "$NPM/$TARGET_NPM"`
    KLD=`bc -l <<< "$KLD/$scale"`
    echo "Adjusting KLD using scale: $scale. New KLD is $KLD"
    ./single_run_train_in_docker_turbo2.sh $1 ${KLD}
done
