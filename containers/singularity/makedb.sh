#!/bin/bash

SINGULARITY_ARGS=(
  --env SPARK_HOME=/opt/spark-2.2.0-bin-hadoop2.6
  --env NCBI_BLAST_PATH=/opt/ncbi-blast-2.13.0+/bin
  --env SLB_WORKDIR=/opt/sparkleblast
  --bind hosts:/etc/hosts 
  --bind data:/tmp/data
)

MAKEDB_ARGS=(
  -p 2 
  -i /tmp/data/swissprot 
  -t /tmp/data/sharedout 
  -m spark://$(hostname):7077
)

rm -rf data/sharedout
singularity exec ${SINGULARITY_ARGS[@]} sparkleblast_latest.sif \
  /opt/sparkleblast/SparkLeMakeDB.sh ${MAKEDB_ARGS[@]}
