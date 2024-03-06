#!/bin/bash


master_node=$(hostname)

SINGULARITY_ARGS=(
  --bind $(mktemp -d run/`hostname`_XXXX):/run
  --bind log/:/opt/spark-2.2.0-bin-hadoop2.6/logs
  --bind work/:/opt/spark-2.2.0-bin-hadoop2.6/work
  --bind hosts-${PJM_JOBID}:/etc/hosts
  --bind data:/tmp/data
  --disable-cache
)
singularity instance start ${SINGULARITY_ARGS[@]} sparkleblast_latest.sif spark-process

echo "starting master on node: ${master_node}"
singularity exec --env SPARK_MASTER_HOST=${master_node} instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-master.sh

sleep 5

echo ${master_node} > master_success-${PJM_JOBID}

