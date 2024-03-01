#!/bin/bash

# Usage: ./split_query.sh DBFile query.fasta num_segments
# Example: ./split_query.sh db.fasta my_sequences.fasta 5

if [ $# -ne 2 ]; then
    echo "Usage: $0 DBFile query.fasta num_segments"
    exit 1
fi

DBFILE=$1
input_file="$2"  
num_segments="$3" 

output_dir="query_segments"
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

for segment_file in "$output_dir"/*.fasta; do
    ./run_spark_jobs.sh "$segment_file"
done

