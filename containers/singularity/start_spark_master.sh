#!/bin/bash


master_node=$(hostname)

singularity instance start \
       --bind $(mktemp -d run/`hostname`_XXXX):/run \
       --bind log/:/opt/spark-2.2.0-bin-hadoop2.6/logs \
       --bind work/:/opt/spark-2.2.0-bin-hadoop2.6/work \
       sparkleblast_latest.sif spark-process

echo "starting master on node: ${master_node}"
singularity exec instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-master.sh

sleep 5

echo $(hostname) > master_success

