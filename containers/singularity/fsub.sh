#!/bin/bash

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

PJSUB_ARGS=(
  -N sparkle-${NPROC}
  -S -j
  -x PJM_LLIO_GFSCACHE=/vol0004
  -g ra000012
  # --llio localtmp-size=10Gi
  -L rscgrp=${RSCGRP}
  -L node=${NPROC}
  -L elapse=${ELAPSE}
  -L jobenv=singularity
  --mpi proc=${NPROC}
  ${email_args}
)

# rm sparkle-* output.* # must be outside pjsub
# rm -rf  run/* log/* work/* data/out/*
pjsub ${PJSUB_ARGS[@]} << EOF
rm -rf  hosts master_success
mkdir -p log run work
mpiexec ./gatherhosts_ips hosts
mpiexec ./start_spark_cluster.sh &
bash -x ./run_spark_jobs.sh ${DBFILE} ${QUERYFILE}
# mpiexec ./stop_spark_cluster.sh &
rm -rf master_success
echo FSUB IS DONE
EOF

# DBFILE=non-rRNA-reads.fa
# Galaxy25-\[Geobacter_metallireducens.fasta\].fasta
# QUERYFILE=sample_text.fa
