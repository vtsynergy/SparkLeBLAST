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
    for file in "$folder/"*[^[:cntrl:]] ; do
      case "${file##*.}" in
        "fasta")  
          cat "$file" >> "$OUTPUT_FILE"
          ;;
        *)  # If not a FASTA file, ignore it
          echo "Skipping non-FASTA file: $file"
          ;;
      esac
    done
  fi
done

echo "FASTA files concatenated successfully into: $OUTPUT_FILE"
