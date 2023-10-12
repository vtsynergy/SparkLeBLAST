#!/bin/bash

rm -f master_success
if [ ${PMIX_RANK} -eq "0" ]; then
    ./start_spark_master.sh &
else
./start_spark_workers.sh &
fi

