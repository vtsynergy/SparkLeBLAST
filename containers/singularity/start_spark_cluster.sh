#!/bin/bash

rm -f master_success
if [ ${PMIX_RANK} -eq "0" ]; then
    bash ./start_spark_master.sh &
else
    bash ./start_spark_workers.sh &
fi

