#!/usr/bin/bash

if [ -z $2 ]; then echo "Usage: $0 \$file \$num_chunks"; exit; fi
file=$1
num_chunks=$2

all_lines=$(wc -l $file | cut -f1 -d \ )
num_lines=$(( ${all_lines} / ${num_chunks} ))
if [ $(( $num_lines % 2 )) -eq 1 ]; then num_lines=$(( ${num_lines} + 1 )); fi
split -l $num_lines $file

