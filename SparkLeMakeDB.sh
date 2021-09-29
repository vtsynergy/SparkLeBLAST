#!/bin/bash


# module load jdk

# masterAddress="spark://ca015.ca.arc.internal:7077"
# dbPath="/work/cascades/karimy/blastDB/nr"
# numPartitions=1000
# dbName="/work/cascades/karimy/blastDB/nr_1000_indexed"
# /home/karimy/spark-2.2.0-bin-hadoop2.6/bin/spark-submit --conf "spark.local.dir=/home/karimy/tmpSpark" --conf "spark.network.timeout=3600" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=120g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=100g" --master $masterAddress --driver-memory 100g --executor-memory 100g --class MakeDB target/scala-2.11/simple-project_2.11-1.0.jar $numPartitions $dbPath "/home/karimy/SparkLeBLAST/formatdbScript" $dbName;

usage() { echo "Usage: ./SparkLeMakeDB.sh -i /path/to/raw/db -t /path/to/output/db -o parse_options (T or F) -p <num_partitions> -w <num_workers> -time <Time in integer minutes> -h hostname_prefix -d /path/to/logs/dir (default current dir)" 1>&2; exit 1; }

#!/bin/bash

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -i|--input)
      INPUT_PATH="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--title)
      OUTPUT_PATH="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--options)
      PARSE_OPTIONS="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--partitioms)
      PARTITIONS="$2"
      shift # past argument
      shift # past value
      ;;
    -w|--workers)
      WORKERS="$2"
      shift # past argument
      shift # past value
      ;;
    -time|--time)
      TIME="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--hostnameprefix)
      HOSTNAME_PREFIX="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--logsdir)
      LOGS_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      shift # past argument
      ;;
  esac
done

# Defaults
# --------

if [ -z ${PARSE_OPTIONS} ]; then
   PARSE_OPTIONS="T"
fi

if [ -z ${TIME} ]; then
   echo "Warning: -time not set, setting to default of 60 minutes"
   TIME="60"
fi

if [ -z ${LOGS_DIR} ]; then
   echo "Warning: -d not set, setting to default to current directory"
   LOGS_DIR=$(pwd)
fi

# Args correctness checks
# -----------------------

if [ -z "${INPUT_PATH}" ] || [ -z "${OUTPUT_PATH}" ] || [ -z ${HOSTNAME_PREFIX} ]; then
    usage
fi

if [ -z ${SPARK_SLURM_PATH} ]; then
    echo "Error: Please set SPARK_SLURM_PATH env. variable"
    exit 1
fi

re='^[0-9]+$'
if ! [[ $TIME =~ $re ]] ; then
   echo "Error: Please enter time in integer number of minutes" >&2; exit 1
fi


echo "INPUT_PATH       = ${INPUT_PATH}"
echo "OUTPUT_PATH      = ${OUTPUT_PATH}"
echo "PARSE_OPTIONS    = ${PARSE_OPTIONS}"
echo "PARTITIONS       = ${PARTITIONS}"
echo "WORKERS          = ${WORKERS}"
echo "Spark SLURM PATH = ${SPARK_SLURM_PATH}"
echo "Job Time         = ${TIME}"
echo "HOSTNAME_PREFIX  = ${HOSTNAME_PREFIX}"

# Launch Spark Cluster using spark-slurm
CLUTER_ID=$(${SPARK_SLURM_PATH}/spark start -t ${TIME} ${WORKERS} | awk '{print $6}')
CLUSTED_DIR="${LOGS_DIR}/x/${CLUTER_ID}"
echo ${CLUSTED_DIR}

# Wait for cluster directory
while [ ! -d ${CLUSTED_DIR} ]; do
   sleep 1;
done

# Get SLURM Job ID
SLURM_JOB_ID=$(cat ${CLUSTED_DIR}/slurm_job_id | awk '{print $4}')
SLURM_JOB_DIR=${LOGS_DIR}/${SLURM_JOB_ID}
echo ${SLURM_JOB_DIR}

# Wait for job directory
while [ ! -d ${SLURM_JOB_DIR} ]; do
   sleep 1;
done

# Get Spark Master Hostname and construct Master Address
SPARK_MASTER_HOSTNAME=$(ls ${SLURM_JOB_DIR}/logs | grep -o "${HOSTNAME_PREFIX}[0-9]*")
echo ${SPARK_MASTER_HOSTNAME}
SPARK_MASTER_ADDRESS="spark://${SPARK_MASTER_HOSTNAME}:7077"
echo ${SPARK_MASTER_ADDRESS}

# Submit Spark job to format the BLAST DB
