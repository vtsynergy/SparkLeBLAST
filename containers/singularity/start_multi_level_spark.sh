#!/bin/bash

# set -x


NPART=${1:-1}
PART_SIZE=$(( $PJM_MPI_PROC / $NPART ))
GROUP_RANK=$(( $PMIX_RANK / $PART_SIZE ))
SUB_RANK=$(( $PMIX_RANK % $PART_SIZE ))
HOSTS_FILE=hosts-${PJM_JOBID}-${GROUP_RANK}
MASTER_FILE=master-${PJM_JOBID}-${GROUP_RANK}

start_master() {

    SINGULARITY_ARGS=(
    --bind $(mktemp -d run/`hostname`_XXXX):/run
    --bind log/:/opt/spark-2.2.0-bin-hadoop2.6/logs
    --bind work/:/opt/spark-2.2.0-bin-hadoop2.6/work
    --bind ${HOSTS_FILE}:/etc/hosts
    --bind data:/tmp/data
    --disable-cache
    )
    singularity instance start ${SINGULARITY_ARGS[@]} sparkleblast_latest.sif spark-process

    echo "starting master on node: $(hostname)"
    singularity exec --env SPARK_MASTER_HOST=$(hostname) instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-master.sh

    sleep 5

    echo $(hostname) > ${MASTER_FILE}
}

start_worker () {
    echo WORKER: $NPART
    while [ ! -e ${MASTER_FILE} ]; do
        sleep 1
    done
    singularity instance start ${SINGULARITY_ARGS[@]} sparkleblast_latest.sif spark-process
    sleep 5
    master_url="spark://$(head -n1 ${MASTER_FILE}):7077"
    echo "Starting worker on node: $(hostname)"
    singularity exec instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-slave.sh ${master_url}

    while [ -e ${MASTER_FILE} ]; do
        sleep 1
    done
}

start_cluster () {
    if [ ${SUB_RANK} -eq "0" ]; then
        start_master
    else
        start_worker
    fi
}

split -n$NPART -d -a1 hosts hosts-${PJM_JOBID}-
start_cluster
