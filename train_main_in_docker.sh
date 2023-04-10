#!/bin/bash

i=$1
variant=$2
export LD_LIBRARY_PATH=/usr/local/cuda/lib64;
cd /mnt/
python3 src/lczero-training/tf/train.py --cfg ${variant}_${i}.yaml --output ${variant}_${i}.gz


