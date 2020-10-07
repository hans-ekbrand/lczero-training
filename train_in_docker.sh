#!/bin/bash

i=$1
variant=$2
export LD_LIBRARY_PATH=/usr/local/cuda/lib64;
cd /mnt/
python3 src/lczero-training/tf/train.py --cfg src/lczero-training/tf/configs/${variant}.yaml --output leela-nets/${variant}/${i}.gz


