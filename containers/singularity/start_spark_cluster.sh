#!/bin/bash

master_node=${1}
num_workers=${2}

./start_spark_master.sh ${master_node} &

wait

mpirun -np ${num_workers} ./start_spark_workers.sh ${master_node} &
