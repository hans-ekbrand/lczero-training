## fully automated reinforcement training with lc0
## until i > 25
## bash small2.sh 1 beta 800
## then
## bash small2.sh 26 beta 4000

## Set up a yaml-file that uses 800 chunks, 25 steps per net, lr = 0.5
echo "variant=beta
chunks=800
steps=25
lr=0.5" > config.1

bash fill.sh config.1 template.yaml 1.yaml

# for i in {1..25}; do
#     # single-run.sh beta 400
# done

	 
