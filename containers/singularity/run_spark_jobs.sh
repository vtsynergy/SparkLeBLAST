#!/bin/bash

SINGULARITY_ARGS=(
  --env SPARK_HOME=/opt/spark-2.2.0-bin-hadoop2.6
  --env NCBI_BLAST_PATH=/opt/ncbi-blast-2.13.0+-src/c++/ReleaseMT/bin
  --env SLB_WORKDIR=/opt/sparkleblast
  --bind hosts:/etc/hosts 
  --bind data:/tmp/data
  --bind ../../SparkLeMakeDB.sh:/opt/sparkleblast/SparkLeMakeDB.sh
  --bind ../../SparkLeBLASTSearch.sh:/opt/sparkleblast/SparkLeBLASTSearch.sh
  --bind ../../blast_args_test.txt:/opt/sparkleblast/blast_args.txt
  --bind ../../blast_makedb_args.txt:/opt/sparkleblast/blast_makedb_args.txt
)

# missing bind: blastSearchScript, blast_*.txt and modify blastSearchScript

# PJM_MPI_PROC # possible word size
OUTPATH="/tmp/$(mktemp -d data/out/$(date -I)_$(hostname)_XXXX)/sharedout"
mkdir -p $OUTPATH/output

MAKEDB_ARGS=(
  -p $PJM_MPI_PROC 
  -w $PJM_MPI_PROC
  # -i /tmp/data/swissprot 
  -i /tmp/data/non-rRNA-reads.fa 
  -t $OUTPATH
  -m spark://$(hostname):7077
)

SEARCH_ARGS=(
  -p $PJM_MPI_PROC 
  -w $PJM_MPI_PROC
  # -q /tmp/data/Galaxy25-\[Geobacter_metallireducens.fasta\].fasta
  -q /tmp/data/sample_text.fa
  -db $OUTPATH
  -m spark://$(hostname):7077
  -o $OUTPATH/output
)

singularity exec "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif \
  /opt/sparkleblast/SparkLeMakeDB.sh ${MAKEDB_ARGS[@]}

singularity exec "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif \
  /opt/sparkleblast/SparkLeBLASTSearch.sh ${SEARCH_ARGS[@]}
