#!/bin/bash

DBFILE=$1
QUERYFILE=$2
OF_PROC=$3
CONTAINER_DATA_DIR=/tmp/data_1
HOST_DATA_DIR=/local/data

NUM_PART=$(( ${PJM_MPI_PROC} - 1 ))
echo "NUM_PART=${NUM_PART}"

MAKEDB_OUT_DIR=makedb_out/${DBFILE}_${NUM_PART}
CONTAINER_MAKEDB_OUT_DIR=${CONTAINER_DATA_DIR}/${MAKEDB_OUT_DIR}
HOST_MAKEDB_OUT_DIR=./data/${MAKEDB_OUT_DIR}

SEARCH_OUT_DIR=search_out/${DBFILE}_${NUM_PART}_${QUERYFILE}/${PJM_JOBID}_$(date -I)_$(hostname)
mkdir -p $(dirname ${HOST_DATA_DIR}/${SEARCH_OUT_DIR})

SINGULARITY_ARGS=(
  --env SPARK_HOME=/opt/spark-2.2.0-bin-hadoop2.6
  --env NCBI_BLAST_PATH=/opt/ncbi-blast-2.13.0+-src/c++/ReleaseMT/bin
  --env SLB_WORKDIR=/opt/sparkleblast
  # --cleanenv
  --disable-cache
  --bind hosts-${PJM_JOBID}:/etc/hosts
  --bind ${HOST_DATA_DIR}:${CONTAINER_DATA_DIR}
  )

SEARCH_ARGS=(
  -p $NUM_PART
  -w $NUM_PART
  -q ${CONTAINER_DATA_DIR}/${QUERYFILE}
  -db ${CONTAINER_MAKEDB_OUT_DIR}
  -dbs ${HOST_MAKEDB_OUT_DIR}
  -m spark://$(hostname):7077
  -o ${CONTAINER_DATA_DIR}/${SEARCH_OUT_DIR}
)

mpiexec bash -c "
mkdir -p ${HOST_DATA_DIR}/makedb_out/${HOST_MAKEDB_OUT_DIR##*/}

# Each rank handles its own files based on the node's rank
if [ \${MPI_COMM_RANK} -ne 0 ]; then
    MPI_RANK_MINUS_ONE=\$(printf '%05d' \$((MPI_COMM_RANK - 1)))

    # Copy the relevant parts from GFS to LFS
    cp ${HOST_MAKEDB_OUT_DIR}/part-\${MPI_RANK_MINUS_ONE}.* ${HOST_DATA_DIR}/makedb_out/${HOST_MAKEDB_OUT_DIR##*/}
    cp ${HOST_MAKEDB_OUT_DIR}/.part-\${MPI_RANK_MINUS_ONE}.* ${HOST_DATA_DIR}/makedb_out/${HOST_MAKEDB_OUT_DIR##*/}
    
    # Copy the query file to the local filesystem
    cp ${CONTAINER_DATA_DIR}/${QUERYFILE} /local/
fi
"
mpiexec -of-proc ${OF_PROC} ./start_spark_cluster.sh &

singularity exec "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif \
  /opt/sparkleblast/SparkLeBLASTSearch.sh ${SEARCH_ARGS[@]}

