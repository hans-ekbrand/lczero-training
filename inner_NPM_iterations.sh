## fully automated reinforcement training including automatically adjusted minimumKLD, varying number of games per net, number of chunks per net, number of steps per net.
## requires an opening book
## 
##            $1     $2             $3              $4         $5     $6    $7    $8    $9
## ./inner.sh turbo2 $HOME          turbo2-book.png 800        16000  1200  250   0.25  25
##            name   home_directory opening book    target_NPM chunks games steps lr    total iterations

## for a quick test
## ./inner.sh turbo2 /mnt          turbo2-book.png 100        400  100 25   0.25  3

## sudo rm -rf ~/kb1-64x6-turbo2/ ~/leelalogs/kb1-64x6-turbo2-t*
## rm -rf ~/leela-nets/turbo2/ ~/leela-training-games/turbo2/ 

initial_KLD=0.000005

## Set up a yaml-file
echo "variant=$1
home=$2
chunks=$5
steps=$7
lr=$8" > config.1
./fill.sh config.1 tf/configs/template-docker.yaml tf/configs/${1}.yaml

## Start training
KLD=$initial_KLD
TARGET_NPM=${4}
for ((i=1;i<=$9;i++)); do
    ./single_run_KLD_book.sh $1 ${KLD} $3 $6
    ## find out the average NPM previous run
    NPM=`grep "final " ~/turbo2.log | tail -n 1 | mawk {'print $22'}`
    scale=`bc -l <<< "$TARGET_NPM/$NPM"`
    echo "npm previous run had ${NPM}, based on KLD ${KLD}, target NPM is ${TARGET_NPM}"
    KLD=`bc -l <<< "$KLD/$scale"`
    echo "Adjusting KLD using scale: $scale. New KLD is $KLD"
done
