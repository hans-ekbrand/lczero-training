## fully automated reinforcement training with varying number of games per net, number of chunks per net, number of steps per net.
## 
##          $1   $2    $3  $4 $5  $6  $7   $8  $9 $10
## outer.sh beta $HOME 400 250 0.25 400 40000 250 0.25 10000
##          name home_directory chunks steps lr games_per_net; chunks, steps lr games_per_net
## for a quick test ./outer.sh turbo2 /mnt 10 2 0.25 0.0000015 40 25 0.25 0.0000015

## sudo rm -rf ~/kb1-64x6-turbo2/ ~/leelalogs/kb1-64x6-turbo2-t*
## rm -rf ~/leela-nets/turbo2/ ~/leela-training-games/turbo2/ 

## ./outer-turbo.sh turbo /mnt 100 25 0.5 100 800 25 0.5 400

## Set up a yaml-file

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

KLD=${10}
TARGET_NPM=200
for i in {1..25}; do
    ./single_run_train_in_docker_turbo2.sh $1 ${KLD}
    ## find out the average NPM previous run
    NPM=`grep "final " ~/turbo2.log | tail -n 1 | cut -d " " -f 23`
    scale=`bc -l <<< "scale=2; $NPM/TARGET_NPM"`
done
