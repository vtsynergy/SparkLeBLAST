#!/bin/bash

NPROC=2
PJSUB_ARGS=(-N mkdb.tmp
            -S -j
            -x PJM_LLIO_GFSCACHE=/vol0004
            -g ra000012
            # --llio localtmp-size=10Gi
            -L node=$NPROC
            -L elapse=0:10:00
            -L jobenv=singularity
            --mpi proc=$NPROC)

pjsub ${PJSUB_ARGS[@]} << EOF
rm hosts
mpiexec ./gatherhosts_ips hosts
mpiexec ./start_spark_cluster.sh &
./makedb.sh
# mpiexec ./stop_spark_cluster.sh &
rm master_success
echo FSUB IS DONE
EOF
