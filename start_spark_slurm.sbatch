#!/bin/bash

# mkdir /work/cascades/karimy/spark/logs/%j
#SBATCH --nodes=32
#  ntasks per node MUST be one, because multiple slaves per work doesn't
#  work well with slurm + spark in this script (they would need increasing 
#  ports among other things)
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#  Beware! $HOME will not be expanded and invalid paths will result Slurm jobs
#  hanging indefinitely with status CG (completing) when calling scancel!
#SBATCH --output="/work/cascades/karimy/spark/logs/%j.out"
#SBATCH --error="/work/cascades/karimy/spark/logs/%j.err"
#SBATCH --time=01:00:00
#SBATCH --exclusive
#SBATCH -A hpcbigdata2

# KARIM SECOND TRIAL
# ulimit -m 31100000

# This section will be run when started by sbatch
if [ "$1" != 'srunning' ]; then
    this=$0
    # I experienced problems with some nodes not finding the script:
    #   slurmstepd: execve(): /var/spool/slurm/job123/slurm_script:
    #   No such file or directory
    # that's why this script is being copied to a shared location to which 
    # all nodes have access to:
    script=/home/karimy/${SLURM_JOBID}_$(basename "$0")
    cp "$this" "$script"

    # This might not be necessary on all clusters
    # module load Spark/2.2.0-Hadoop-2.6-Java-1.8.0_144
    module load jdk

    export sparkLogs=/home/karimy/spark/logs/%j
    export sparkTmp=/home/karimy/spark/tmp/%j
    mkdir -p "$sparkLogs" "$sparkTmp"

    export SPARK_ROOT=/home/karimy/spark-2.2.0-bin-hadoop2.6
    export SPARK_HOME=$SPARK_ROOT
    export SPARK_WORKER_DIR=$sparkLogs
    export SPARK_LOCAL_DIRS=$sparkLogs
    export SPARK_MASTER_PORT=7077
    export SPARK_MASTER_WEBUI_PORT=8080
    export SPARK_WORKER_CORES=$SLURM_CPUS_PER_TASK
    export SPARK_DAEMON_MEMORY=$(( $SLURM_MEM_PER_CPU * $SLURM_CPUS_PER_TASK / 2 ))m
    export SPARK_MEM=$SPARK_DAEMON_MEMORY

    srun "$script" 'srunning'
# If run by srun, then decide by $SLURM_PROCID whether we are master or worker
# KARIM 4/26/2018
# ulimit -m 31100000
else
    source "$SPARK_ROOT/sbin/spark-config.sh"
    source "$SPARK_ROOT/bin/load-spark-env.sh"
    if [ $SLURM_PROCID -eq 0 ]; then
        export SPARK_MASTER_IP=$(hostname)
        MASTER_NODE=$(scontrol show hostname $SLURM_NODELIST | head -n 1)

        # The saved IP address + port is necessary alter for submitting jobs
        echo "spark://$SPARK_MASTER_IP:$SPARK_MASTER_PORT" > "$sparkLogs/${SLURM_JOBID}_spark_master"

        "$SPARK_ROOT/bin/spark-class" org.apache.spark.deploy.master.Master \
            --ip $SPARK_MASTER_IP                                           \
            --port $SPARK_MASTER_PORT                                       \
            --webui-port $SPARK_MASTER_WEBUI_PORT
    
    # else
    fi
        # ulimit -m 31100000
        # $(scontrol show hostname) is used to convert e.g. host20[39-40]
        # to host2039 this step assumes that SLURM_PROCID=0 corresponds to 
        # the first node in SLURM_NODELIST !
        MASTER_NODE=spark://$(scontrol show hostname $SLURM_NODELIST | head -n 1):7077
        "$SPARK_ROOT/bin/spark-class" org.apache.spark.deploy.worker.Worker $MASTER_NODE
    # fi
fi
