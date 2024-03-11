#!/bin/bash

# Usage: ./split_query.sh query.fasta num_segments /path/to/output_dir
# Example: ./split_query.sh my_sequences.fasta 5 /path/to/output_dir

if [ $# -ne 3 ]; then
    echo "Usage: $0 query.fasta num_segments /path/to/output_dir"
    exit 1
fi

input_file="$1"  
num_segments="$2" 
output_dir="$3"

total_sequences=$(grep -c '^>' "$input_file")

sequences_per_segment=$(( (total_sequences + num_segments - 1) / num_segments))

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

