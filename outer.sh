## fully automated reinforcement training with varying number of games per net, number of chunks per net, number of steps per net.
## 
##          $1   $2    $3  $4 $5  $6  $7   $8  $9 $10
## outer.sh beta $HOME 800 25 0.5 400 4000 25 0.5 800
##          name home_directory chunks steps lr games_per_net; chunks, steps lr games_per_net
## for a quick test ./outer.sh beta $HOME 10 2 0.5 5 40 25 0.5 20

## Set up a yaml-file

echo "variant=$1
home=$2
chunks=$3
steps=$4
lr=$5" > config.1

./fill.sh config.1 tf/configs/template.yaml tf/configs/${1}.yaml

for i in {1..25}; do
    ./single_run.sh $1 $6
done

echo "variant=$1
home=$2
chunks=$7
steps=$8
lr=$9" > config.2

bash fill.sh config.2 tf/configs/template.yaml tf/configs/${1}.yaml

for i in {1..50}; do
    ./single_run.sh $1 ${10}
done