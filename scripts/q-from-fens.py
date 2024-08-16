from lczero.backends import Weights, Backend, GameState
import pandas as pd

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input_file', help='the file that holds the positions, one FEN per line.', required=True)
args = parser.parse_args()

my_file = args.input_file

# Initialize weights and backend
w = Weights()
b = Backend(weights=w)
# b = Backend(weights=w, backend='demux', options='backend=cuda,(gpu=0),(gpu=1),(gpu=2),(gpu=3),(gpu=4),(gpu=5)')

# Read FENs from file
df = pd.read_table(my_file, sep=",", header=None)

# Define the chunk size
chunk_size = 1024

def fen_to_gamestate(fen):
    return(GameState(fen).as_input(b))

# Process input in chunks
for start in range(0, len(df), chunk_size):
    end = min(start + chunk_size, len(df))
    chunk = df.iloc[start:end, 0].map(fen_to_gamestate)
    results = b.evaluate(*chunk)

    # Extract individual results
    for i, result in enumerate(results):
        print(df.iloc[start + i, 0] + f", {result.q()}")

