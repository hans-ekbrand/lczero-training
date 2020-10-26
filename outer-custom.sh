## fully automated reinforcement training with varying number of games per net, number of chunks per net, number of steps per net.
## 
##          $1   $2    $3  $4 $5  $6  $7   $8  $9 $10
## outer-custom.sh without_adjudication_fixed_nodes-test $HOME 800 25 0.5 400 4000 25 0.5 800
##          name home_directory chunks steps lr games_per_net; chunks, steps lr games_per_net
## To restart from scratch (sudo needed since training is in docker as root).
## sudo rm -rf ~/kb1-64x6-without_adjudication_fixed_nodes ~/leela-nets/without_adjudication_fixed_nodes ~/leela-training-games/without_adjudication_fixed_nodes ~/without_adjudication_fixed_nodes.log ~/leelalogs/kb1-64x6-without_adjudication_fixed_nodes-train ~/leelalogs/kb1-64x6-without_adjudication_fixed_nodes-test

## Set up a yaml-file

echo "variant=$1
home=$2
chunks=$3
steps=$4
lr=$5" > config.1

./fill.sh config.1 tf/configs/template-docker.yaml tf/configs/${1}.yaml

## restarted after game 6.gz was generated
for i in {7..25}; do
    ./single_run_train_in_docker_tb_no_adjudication.sh $1 $6    
done

echo "variant=$1
home=$2
chunks=$7
steps=$8
lr=$9" > config.2

./fill.sh config.2 tf/configs/template-docker.yaml tf/configs/${1}.yaml

for i in {1..150}; do
    ./single_run_train_in_docker_tb_no_adjudication.sh $1 ${10}        
done
