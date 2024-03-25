#!/bin/bash

if [ $# -ne 4 ]; then
    echo "Usage: $0 <input_tar_file> <log_file> <query_file> <db_file>"
    exit 1
fi

input_tar="$1"
log_file="$2"
query_file="$3"
db_file="$4"

echo "Tar file used: $input_tar"
# Extract the input tarball
tar -zxvpf "$input_tar"

# Get the actual directory name (excluding the version)
untarred_dir=$(tar -tf "$input_tar" | head -n 1 | cut -f1 -d'/')

# Compile the source code
cd "$untarred_dir/c++"
./configure
echo "Compiling BLASTP..."
echo "Time taken to compile" > "$log_file"
time make -j >> "$log_file"

# Run BLASTP with timing
echo "Running BLASTP"
echo "Time taken to run BLASTP" >> "$log_file"
OMP_NUM_THREADS=48 /usr/bin/time -a -o "$log_file" ./ReleaseMT/bin/blastp -query "$query_file" -db "$db_file" -num_threads 48

echo "Compilation and BLASTP completed! Output saved to $log_file"

