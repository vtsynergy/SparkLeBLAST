#!/bin/bash

# set -x

# BEGIN REMOVE THIS SECTION
PMIX_RANK=1
# END REMOVE THIS SECTION

NPART=${1:-1}

start_master() {
    master_node=$(hostname)

    SINGULARITY_ARGS=(
    --bind $(mktemp -d run/`hostname`_XXXX):/run
    --bind log/:/opt/spark-2.2.0-bin-hadoop2.6/logs
    --bind work/:/opt/spark-2.2.0-bin-hadoop2.6/work
    --bind hosts:/etc/hosts
    --bind data:/tmp/data
    --disable-cache
    )
    singularity instance start ${SINGULARITY_ARGS[@]} sparkleblast_latest.sif spark-process

    echo "starting master on node: ${master_node}"
    singularity exec --env SPARK_MASTER_HOST=${master_node} instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-master.sh

    sleep 5

    echo ${master_node} > master_success
}

start_worker () {
    echo WORKER: $NPART
    while [ ! -e "master_success" ]; do
        sleep 1
    done
    master_node=$(head -n 1 master_success)
    singularity instance start ${SINGULARITY_ARGS[@]} sparkleblast_latest.sif spark-process
    sleep 5
    master_url="spark://${master_node}:7077"
    echo "Starting worker on node: $(hostname)"
    singularity exec instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-slave.sh ${master_url}

    while [ -e "master_success" ]; do
        sleep 1
    done
}

start_cluster () {
    if [ ${PMIX_RANK} -eq "0" ]; then
        start_master
    else
        start_worker
    fi
}

