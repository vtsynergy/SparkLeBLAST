#!/bin/bash


echo "stopping master on node: ${master_node}"
singularity exec instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/stop-master.sh
singularity instance stop spark-process

