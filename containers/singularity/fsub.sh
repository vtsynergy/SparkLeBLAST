#!/bin/bash

NPROC=2
PJSUB_ARGS=(-N mkdb.tmp
            -x PJM_LLIO_GFSCACHE=/vol0004
            -g ra000012
            --llio localtmp-size=10Gi
            -L node=$NPROC
            -L elapse=0:10:00
            -L jobenv=singularity
            --mpi proc=$NPROC)

pjsub ${PJSUB_ARGS[@]} << EOF
date
rm hosts
mpiexec ./gatherhosts_ips hosts
mpiexec ./start_spark_cluster.sh &
echo "PID: $PID"
./makedb.sh
echo FSUB IS DONE
date
EOF
