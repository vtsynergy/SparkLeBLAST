#!/bin/bash

OUTPUT_FILE="combined_output.fasta"

if [ $# -eq 0 ]; then
  echo "Error: Please provide a directory path with all of the segmented output as an argument."
  echo "$0 /path/to/directory/"
  exit 1
fi

directory="$1"

for folder in "$directory"/*; do
  if [ -d "$folder" ]; then
    fasta_files=($(ls "$folder"/*.fasta | sort -V))
    for file in "${fasta_files[@]}"; do
      cat "$file" >> "$OUTPUT_FILE"
    done
  fi
done

echo "FASTA files concatenated successfully into: $OUTPUT_FILE"
