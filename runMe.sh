#!/bin/bash

set -e


## Run analyses first for the simulated data and then for the cancer cell line data.

dirs=(simulated_data cancer_cell_lines runtime_analysis) 

for dir in ${dirs[*]}
do
    cd $dir
    ./runMe.sh
    cd ../
done

