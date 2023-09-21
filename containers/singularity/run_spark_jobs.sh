#!/bin/bash

DOCKER_DATADIR=/tmp/data

SINGULARITY_ARGS=(
  --env SPARK_HOME=/opt/spark-2.2.0-bin-hadoop2.6
  --env NCBI_BLAST_PATH=/opt/ncbi-blast-2.13.0+-src/c++/ReleaseMT/bin
  --env SLB_WORKDIR=/opt/sparkleblast
  --bind hosts:/etc/hosts
  --bind data:${DOCKER_DATADIR}
  --bind ../../SparkLeMakeDB.sh:/opt/sparkleblast/SparkLeMakeDB.sh
  --bind ../../SparkLeBLASTSearch.sh:/opt/sparkleblast/SparkLeBLASTSearch.sh
  --bind ../../blast_args_test.txt:/opt/sparkleblast/blast_args.txt
  --bind ../../blast_makedb_args.txt:/opt/sparkleblast/blast_makedb_args.txt
)

# missing bind: blastSearchScript, blast_*.txt and modify blastSearchScript

# PJM_MPI_PROC # possible word size

DBFILE=$1
QUERYFILE=$2

OUTPATH=makedb_out/${DBFILE}_${PJM_MPI_PROC}
mkdir -p ./data/${OUTPATH}
mkdir -p ./data/final_output/${OUTPATH}
MAKEDB_OUTPATH=${DOCKER_DATADIR}/${OUTPATH}

MAKEDB_ARGS=(
  -p $PJM_MPI_PROC
  -w $PJM_MPI_PROC
  -i ${DOCKER_DATADIR}/${DBFILE}
  -t ${MAKEDB_OUTPATH}
  -m spark://$(hostname):7077
)

TEMPDIR=$(mktemp -d ./data/final_output/$(date -I)_$(hostname)_XXXX)
FINAL_OUTPATH=$(dirname ${DOCKER_DATADIR})/${TEMPDIR}

SEARCH_ARGS=(
  -p $PJM_MPI_PROC
  -w $PJM_MPI_PROC
  -q ${DOCKER_DATADIR}/${QUERYFILE}
  -db ${MAKEDB_OUTPATH}
  -m spark://$(hostname):7077
  -o ${FINAL_OUTPATH}
)

if [ ! -e ${HOST_OUTPATH} ]; then
    singularity exec "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif \
        /opt/sparkleblast/SparkLeMakeDB.sh ${MAKEDB_ARGS[@]}
fi

singularity exec "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif \
  /opt/sparkleblast/SparkLeBLASTSearch.sh ${SEARCH_ARGS[@]}
