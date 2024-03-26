#!/bin/bash

if [ ${PMIX_RANK} -eq "0" ]; then
    sleep 10
    ./stop_spark_master.sh
    rm master_success-${SLURM_JOBID} hosts-${SLURM_JOBID}
else
    singularity instance stop spark-process
fi
