#!/bin/bash

DBFILE=$1
QUERYFILE=$2

#SBATCH --nodes=1                 
#SBATCH --time=1:00:00              
#SBATCH -p p100_dev_q
#SBATCH -A hpcbigdata2
#SBATCH --exclusive 

CONTAINER_DATA_DIR=/tmp/data
HOST_DATA_DIR=./data


NUM_PART=$(( ${PJM_MPI_PROC} - 1 ))
#NUM_PART=$(( ${NPROC} - 1 ))
echo "NUM_PART=${NUM_PART}"

MAKEDB_OUT_DIR=makedb_out/${DBFILE}_${NUM_PART}
CONTAINER_MAKEDB_OUT_DIR=${CONTAINER_DATA_DIR}/${MAKEDB_OUT_DIR}
HOST_MAKEDB_OUT_DIR=${HOST_DATA_DIR}/${MAKEDB_OUT_DIR}
mkdir -p $(dirname ${HOST_MAKEDB_OUT_DIR})

SEARCH_OUT_DIR=search_out/${DBFILE}_${NUM_PART}_${QUERYFILE}/${SLURM_JOBID}_$(date -I)_$(hostname)
mkdir -p $(dirname ${HOST_DATA_DIR}/${SEARCH_OUT_DIR})

SINGULARITY_ARGS=(
  --env SPARK_HOME=/opt/spark-2.2.0-bin-hadoop2.6
  --env NCBI_BLAST_PATH=/opt/ncbi-blast-2.13.0+-src/c++/ReleaseMT/bin
  --env SLB_WORKDIR=/opt/sparkleblast
  # --cleanenv
  --disable-cache
  --bind hosts-${SLURM_JOBID}:/etc/hosts
  --bind ${HOST_DATA_DIR}:${CONTAINER_DATA_DIR}
)

MAKEDB_ARGS=(
  -p $NUM_PART
  -w $NUM_PART
  -i ${CONTAINER_DATA_DIR}/${DBFILE}
  -t ${CONTAINER_MAKEDB_OUT_DIR}
  -m spark://$(hostname):7077
)

SEARCH_ARGS=(
  -p $NUM_PART
  -w $NUM_PART
  -q ${CONTAINER_DATA_DIR}/${QUERYFILE}
  -db ${CONTAINER_MAKEDB_OUT_DIR}
  -m spark://$(hostname):7077
  -o ${CONTAINER_DATA_DIR}/${SEARCH_OUT_DIR}
)

echo "MPI RANK is ${OMPI_COMM_WORLD_LOCAL_RANK}"

if [ ! -e ${HOST_MAKEDB_OUT_DIR}/database.dbs ]; then
    if [ ${PMIX_RANK} -eq 0 ]; then
        rm -rf ${HOST_MAKEDB_OUT_DIR}
    fi
    singularity exec "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif \
        /opt/sparkleblast/SparkLeMakeDB.sh ${MAKEDB_ARGS[@]}
fi
singularity exec "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif \
  /opt/sparkleblast/SparkLeBLASTSearch.sh ${SEARCH_ARGS[@]}

