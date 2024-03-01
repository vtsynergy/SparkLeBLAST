#!/bin/bash

# Usage: ./split_fasta.sh input.fasta num_segments
# Example: ./split_fasta.sh my_sequences.fasta 5

if [ $# -ne 2 ]; then
    echo "Usage: $0 input.fasta num_segments"
    exit 1
fi

input_file="$1"  # Input FASTA file
num_segments="$2"  # Number of segments to split into

output_dir="fasta_segments"
mkdir -p "$output_dir"

total_sequences=$(grep -c '^>' "$input_file")

sequences_per_segment=$((total_sequences / num_segments))

awk -v num_seqs="$sequences_per_segment" -v num_segments="$num_segments" '
  BEGIN {n_seq=0; part=0; outfile=sprintf("'$output_dir'/segment_%02d.fasta", part)}
  /^>/ {
    if (n_seq++ % num_seqs == 0 && part != num_segments) {
      close(outfile);
      part++;
      outfile=sprintf("'$output_dir'/segment_%02d.fasta", part);
    }
    print >> outfile;
    next;
  }
  {print >> outfile}
  END {close(outfile)}
' "$input_file"

echo "$num_segments segments made"
echo "Segments saved in the '$output_dir' directory."

