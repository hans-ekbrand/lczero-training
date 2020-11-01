## sudo rm -rf ~/leela-nets/turbo4 ~/leela-training-games/turbo4 ~/kb1-64x6-turbo4 ~/src/lczero-training/leelalogs/kb1-64x6-turbo4-t* ~/turbo4.log ~/turbo4_actual_book.pgn

## Experiment 2, 250 steps per net in the first phase.

## Quick test
#./inner_NPM_iterations.sh turbo4 /mnt start-6-men.pgn 800  400  400 250   0.25  10 > ~/turbo4.log

## suffle book
## make unique, shuffle, format as pgn-fen, save

#grep "FEN" start-6-men.pgn | sort | uniq | unsort --random > 6-men.fens
#sed 's/$/\n\n*\n\n/' 6-men.fens > start-6-men-shuffled.pgn

#./inner_NPM_iterations.sh turbo4 /mnt start-6-men-shuffled.pgn 800  16000  1200 250   0.25  3 >> ~/turbo4.log

## start-7-men.pgn is shuffled, so not same order as start-6-men.pgn
#./inner_NPM_iterations.sh turbo4 /mnt start-7-men.pgn 800  16000  1200 250   0.25  10 >> ~/turbo4.log

#./inner_NPM_iterations.sh turbo4 /mnt start-8-men.pgn 800  16000  1200 250   0.25  10 >> ~/turbo4.log

# ./inner_NPM_iterations.sh turbo4 /mnt start-9-men.pgn 800  20000  4000 250   0.25  10 >> ~/turbo4.log

# ./inner_NPM_iterations.sh turbo4 /mnt start-10-men.pgn 800  20000  4000 250   0.25  10 >> ~/turbo4.log

# ./inner_NPM_iterations.sh turbo4 /mnt start-11-men.pgn 800  20000  4000 250   0.25  10 >> ~/turbo4.log

# ./inner_NPM_iterations.sh turbo4 /mnt start-12-men.pgn 800  20000  4000 250   0.25  10 >> ~/turbo4.log

# ./inner_NPM_iterations.sh turbo4 /mnt start-6-9-men-dodgy-mix.pgn 800  20000  4000 250   0.25  10 >> ~/turbo4.log

./inner_NPM_iterations.sh turbo4 /mnt selected_1-2.pgn 800  20000  4000 250   0.25  10 >> ~/turbo4.log

