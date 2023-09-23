#!/bin/bash

NPROC=$1
DBFILE=$2
QUERYFILE=$3

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
  -L elapse=1:00:00
  -L jobenv=singularity
  --mpi proc=${NPROC}
  ${email_args}
)

# rm mkdb.tmp.* output.* # must be outside pjsub
# rm -rf  run/* log/* work/* data/out/*
# rm -rf  hosts master_success
pjsub ${PJSUB_ARGS[@]} << EOF
mkdir -p log run work
mpiexec ./gatherhosts_ips hosts
mpiexec ./start_spark_cluster.sh &
./run_spark_jobs.sh ${DBFILE} ${QUERYFILE}
# mpiexec ./stop_spark_cluster.sh &
rm master_success
echo FSUB IS DONE
EOF

# DBFILE=non-rRNA-reads.fa
# Galaxy25-\[Geobacter_metallireducens.fasta\].fasta
# QUERYFILE=sample_text.fa
