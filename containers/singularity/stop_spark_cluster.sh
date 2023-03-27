#!/bin/bash

num_workers=${1}

rm master_success

wait

sleep 10

./stop_spark_master.sh
