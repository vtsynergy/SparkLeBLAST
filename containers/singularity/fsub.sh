#!/bin/bash

NPROC=3
PJSUB_ARGS=(-N mkdb.tmp
            -S -j
            -x PJM_LLIO_GFSCACHE=/vol0004
            -g ra000012
            # --llio localtmp-size=10Gi
            -L rscgrp=small
            -L node=$NPROC
            -L elapse=0:10:00
            -L jobenv=singularity
            --mpi proc=$NPROC)

rm mkdb.tmp.* output.* # must be outside pjsub
rm -rf  run/* log/* work/* data/out/*
rm -rf  hosts master_success
pjsub ${PJSUB_ARGS[@]} << EOF
mpiexec ./gatherhosts_ips hosts
mpiexec ./start_spark_cluster.sh &
./makedb.sh
# mpiexec ./stop_spark_cluster.sh &
rm master_success
echo FSUB IS DONE
EOF
