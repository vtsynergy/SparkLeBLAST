#!/bin/bash
HOST_DATA_DIR=$1

# echo $(hostname)
# echo ${master_node}
SINGULARITY_ARGS=(
  --bind $(mktemp -d run/`hostname`_${PMIX_RANK}_XXXX):/run
  --bind log/:/opt/spark-2.2.0-bin-hadoop2.6/logs
  --bind work/:/opt/spark-2.2.0-bin-hadoop2.6/work
  --bind hosts-${SLURM_JOBID}:/etc/hosts
  --bind ${HOST_DATA_DIR}:/tmp/data
  --disable-cache
)

# if [[ $(hostname) != "${master_node}" ]]; then
    while [ ! -e "master_success-${SLURM_JOBID}" ]; do
        sleep 1
    done
    master_node=$(head -n 1 master_success-${SLURM_JOBID})
    singularity instance start ${SINGULARITY_ARGS[@]} sparkleblast_latest.sif spark-process
    sleep 5
    master_url="spark://${master_node}:7077"
    echo "Starting worker on node: $(hostname)"
    singularity exec instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-slave.sh ${master_url}

    while [ -e "master_success-${SLURM_JOBID}" ]; do
        sleep 1
    done
# fi
