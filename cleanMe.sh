#!/bin/bash

set -ev


dirs=(simulated_data cancer_cell_lines) 

for dir in ${dirs[*]}
do
    cd $dir
    ./cleanMe.sh
    cd ../
done

