#!/bin/bash

set -x

DBFILE=$1
QUERYFILE=$2
NPROC=$3
ELAPSE=${4:-30:00}

USAGE="$0 \${NPROC}"
if [ -z ${NPROC} ]; then
  echo "NPROC not set!"
  echo ${USAGE}
  exit 1
fi
if [ ! -f data/${DBFILE} ]; then
    echo "Could not find data/${DBFILE}"
    echo ${USAGE}
    exit 1;
fi
if [ ! -f data/${QUERYFILE} ]; then
    echo "Could not find data/${QUERYFILE}"
    echo ${USAGE}
    exit 1;
fi
if email=$(git config --get user.email); then
    email_args="-m b,e --mail-list ${email}"
else
    echo "$0 WARNING: git email not set!"
fi

if [ ${NPROC} -gt 384 ]; then
  RSCGRP=large;
else
  RSCGRP=small;
fi

OUTPUT_DIR=output

NAME=sparkle-${NPROC}
PJSUB_ARGS=(
  -N ${NAME}
  -S # -j
  -o ${OUTPUT_DIR}/%j-${NAME}.stdout
  -e ${OUTPUT_DIR}/%j-${NAME}.stderr
  --spath ${OUTPUT_DIR}/%j-${NAME}.stat
  -x PJM_LLIO_GFSCACHE=/vol0004
  -x SINGULARITY_TMPDIR=/local
  -g ra000012
  # --llio localtmp-size=10Gi
  -L rscgrp=${RSCGRP}
  -L node=${NPROC}
  -L elapse=${ELAPSE}
  -L jobenv=singularity
  --mpi proc=${NPROC}
  ${email_args}
)

if [[ "${CLEARALL^^}" =~ ^(YES|ON|TRUE)$ ]]; then 
  # must be outside pjsub
  rm -rf output run log work data/makedb_out data/search_out
fi

mkdir -p ${OUTPUT_DIR}
pjsub ${PJSUB_ARGS[@]} << EOF
OF_PROC=${OUTPUT_DIR}/\${PJM_JOBID}-${NAME}/mpi

rm -rf  hosts master_success
mkdir -p log run work \$(dirname \${OF_PROC})

mpiexec -of-proc \${OF_PROC} ./gatherhosts_ips hosts
mpiexec -of-proc \${OF_PROC} ./start_spark_cluster.sh &
bash -x ./run_spark_jobs.sh ${DBFILE} ${QUERYFILE}
# mpiexec -of-proc \${OF_PROC} ./stop_spark_cluster.sh &
rm -rf master_success
echo FSUB IS DONE
EOF

# DBFILE=non-rRNA-reads.fa
# Galaxy25-\[Geobacter_metallireducens.fasta\].fasta
# QUERYFILE=sample_text.fa
