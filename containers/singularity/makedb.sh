#!/bin/bash

SINGULARITY_ARGS=(
  --env SPARK_HOME=/opt/spark-2.2.0-bin-hadoop2.6
  --env NCBI_BLAST_PATH=/opt/ncbi-blast-2.13.0+/bin
  --env SLB_WORKDIR=/opt/sparkleblast
  --bind hosts:/etc/hosts 
  --bind data:/tmp/data
  --bind ../../SparkLeMakeDB.sh:/opt/sparkleblast/SparkLeMakeDB.sh
)

# PJM_MPI_PROC # possible word size

MAKEDB_ARGS=(
  -p $PJM_MPI_PROC 
  -w $PJM_MPI_PROC
  -i /tmp/data/swissprot 
  -t /tmp/$(mktemp -d data/out/`hostname`_XXXX)/sharedout 
  -m spark://$(hostname):7077
)

rm -rf output.* run/* log/* work/* data/out/*
singularity exec "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif \
  /opt/sparkleblast/SparkLeMakeDB.sh ${MAKEDB_ARGS[@]}
