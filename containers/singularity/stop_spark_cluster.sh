#!/bin/bash

if [ ${PMIX_RANK} -eq "0" ]; then
    sleep 10
    ./stop_spark_master.sh
    rm master_success
else
    singularity instance stop spark-process
fi
