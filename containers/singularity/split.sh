#!/usr/bin/bash

file=$1
num_chunks=$2

all_lines=$(wc -l $file | cut -f1 -d \ )
num_lines=$(( $(all_lines) / $(num_chunks) ))
if [ $( $(( $num_lines % 2 )) -eq 1 ]; then num_lines=$(( $(num_lines) + 1 )); fi

slit -l $num_lines $file

