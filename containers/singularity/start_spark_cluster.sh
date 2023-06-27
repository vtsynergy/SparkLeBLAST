#!/bin/bash

rm -f master_success
if [ ${PMIX_RANK} -eq "0" ]; then
    ./start_spark_master.sh &
fi
./start_spark_workers.sh &

