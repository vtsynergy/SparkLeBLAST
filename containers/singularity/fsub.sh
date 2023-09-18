#!/bin/bash

DBFILE=$1
QUERYFILE=$2

USAGE="$0 \${NPROC}"
if [ -z ${NPROC} ] || [ ! -e "data/${DBFILE}" ] || [ ! -e "data/${QUERYFILE}" ]; then
  echo "NPROC not set!" # TODO separate errors
  echo ${USAGE}
  exit 1
fi
if [ ${NPROC} -gt 384 ]; then 
  RSCGRP=large;
else
  RSCGRP=small;
fi

PJSUB_ARGS=(
  -N slarkle-${NPROC}
  -S -j
  -x PJM_LLIO_GFSCACHE=/vol0004
  -g ra000012
  # --llio localtmp-size=10Gi
  -L rscgrp=${RSCGRP}
  -L node=${NPROC}
  -L elapse=10:00:00
  -L jobenv=singularity
  --mpi proc=${NPROC}
)

# rm mkdb.tmp.* output.* # must be outside pjsub
# rm -rf  run/* log/* work/* data/out/*
# rm -rf  hosts master_success
echo pjsub ${PJSUB_ARGS[@]} 
cat << EOF
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
