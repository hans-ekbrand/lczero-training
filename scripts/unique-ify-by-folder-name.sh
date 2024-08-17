#!/bin/bash

## usage: there is special command to run this command: 
## bash ~/unique-ify-by-folder-name-outer.sh

find -L $1 -type f -name 'game*gz' -exec file-rename "s/game/${1}_game/" {} +
