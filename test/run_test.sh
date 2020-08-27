#!/bin/bash

# Download and extract dataset
mkdir -p test_data
wget https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/swissprot.gz
gunzip -c test_data/swissprot.gz test_data/swissprot

# Sample query sequences from dataset

# Partition and format database

# Run SparkLeBLAST search

# Run NCBI BLAST search

# Compare results
