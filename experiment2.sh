## Experiment 2, 250 steps per net in the first phase.

## Quick test
## ./inner_NPM_iterations.sh turbo2 /mnt turbo2-book.png 100  400  100 25   0.25  3 > ~/turbo2.log

# ## Real run
# ## 10 iterations with only fresh games in training
#./inner_NPM_iterations.sh turbo3 /mnt          start-6-men.pgn 800        400  400  250   0.25  10 > ~/turbo3.log

# ## 2 iterations with 1200 new games of a total of 16000 games per net in training
## This will randomly change the index of the opening book. Preferable use an opening book that is much larger than the number of games for these two phases
./inner_NPM_iterations.sh turbo3 /mnt          start-6-men.pgn 800        16000  1200  250   0.25  2 >> ~/turbo3.log

## Fresh position in the opening book, but the new book is shuffled externally anyway.
## 14 iterations with 1200 new games of a total of 16000 games per net in training with 7-men
./inner_NPM_iterations.sh turbo3 /mnt          start-7-men.pgn 800        16000  1200  250   0.25  14 >> ~/turbo3.log

# ## 10 iterations with 1200 new games of a total of 16000 games per net in training with 7-men
# ./inner_NPM_iterations.sh turbo3 /mnt          start-8-men.pgn 800        16000  1200  250   0.25  6 >> ~/turbo3.log

