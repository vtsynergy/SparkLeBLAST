#!/bin/bash

master_node=$(hostname)

OUT_DIR=$(realpath "${PJM_STDOUT_PATH%.*}")
LOG_DIR=${OUT_DIR}/$PMIX_RANK/log
RUN_DIR=${OUT_DIR}/$PMIX_RANK/run
WORK_DIR=${OUT_DIR}/$PMIX_RANK/work
mkdir -p "$LOG_DIR" "$RUN_DIR" "$WORK_DIR"

SINGULARITY_ARGS=(
  --bind "$RUN_DIR:/run"
  --bind "$LOG_DIR:/opt/spark-2.2.0-bin-hadoop2.6/logs"
  --bind "$WORK_DIR:/opt/spark-2.2.0-bin-hadoop2.6/work"
  --bind "hosts-${PJM_JOBID}:/etc/hosts"
  --bind data:/tmp/data
  --disable-cache
  --cleanenv
)

start_master () {
  singularity instance start "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif spark-process
  echo "starting master on node: ${master_node}"
  singularity exec --env SPARK_MASTER_HOST="${master_node}" instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-master.sh
  sleep 5
  echo "${master_node}" > "master_success-${PJM_JOBID}"
}

start_worker () {
  while [ ! -e "master_success-${PJM_JOBID}" ]; do sleep 1; done
  master_node=$(head -n 1 "master_success-${PJM_JOBID}")
  singularity instance start "${SINGULARITY_ARGS[@]}" sparkleblast_latest.sif spark-process
  sleep 5
  master_url="spark://${master_node}:7077"
  echo "Starting worker on node: $(hostname)"
  singularity exec instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-slave.sh "${master_url}"
  while [ -e "master_success-${PJM_JOBID}" ]; do sleep 1; done
}

rm -f "master_success-${PJM_JOBID}"
if [ "${PMIX_RANK}" -eq "0" ]; then
  start_master &
else
  start_worker &
fi

