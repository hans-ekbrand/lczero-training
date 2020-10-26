## Quick test
## ./inner_NPM_iterations.sh turbo2 /mnt turbo2-book.png 100  400  100 25   0.25  3 > ~/turbo2.log
## Real run
## 10 iterations with only fresh games in training
./inner_NPM_iterations.sh turbo2 /mnt          start-6-men.pgn 800        400  400  125   0.25  10 > ~/turbo2.log
## I accidentally killed the process after 2 nets, and restarted manually after that, which increases the effective iterations from 10 to 12 at the first step

## 25 iterations with 1200 new games of a total of 16000 games per net in training
./inner_NPM_iterations.sh turbo2 /mnt          start-6-men.pgn 800        16000  1200  250   0.25  25 >> ~/turbo2.log


