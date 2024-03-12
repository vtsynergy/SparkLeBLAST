#!/bin/bash

if [ ${PMIX_RANK} -eq "0" ]; then
    sleep 10
    ./stop_spark_master.sh
    rm master_success-${PJM_JOBID} hosts-${PJM_JOBID}
else
    singularity instance stop spark-process
fi
