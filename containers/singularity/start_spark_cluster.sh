#!/bin/bash
HOST_DATA_DIR=$1


rm -f master_success-${SLURM_JOBID}
if [ ${PMIX_RANK} -eq "0" ]; then
    bash ./start_spark_master.sh ${HOST_DATA_DIR} &
else
    bash ./start_spark_workers.sh ${HOST_DATA_DIR} &
fi

