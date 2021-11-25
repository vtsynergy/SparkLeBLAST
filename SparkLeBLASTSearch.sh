#!/bin/bash


# module load jdk


usage() { echo "Usage: ./SparkLeBLASTSearch.sh -q /path/to/query -db /path/to/formatted/db -gop gap_open -gex gap_extend -nalign num_alignments -w <num_workers> -time <Time in integer minutes> -h hostname_prefix -d /path/to/logs/dir (default current dir)" 1>&2; exit 1; }


while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -q|--query)
      QUERY="$2"
      shift # past argument
      shift # past value
      ;;
    -db|--database)
      DATABASE="$2"
      shift # past argument
      shift # past value
      ;;
    -gop|--gapopen)
      GAP_OPEN="$2"
      shift # past argument
      shift # past value
      ;;
    -gex|--gapextend)
      GAP_EXTEND="$2"
      shift # past argument
      shift # past value
      ;;
    -nalign|--numalignments)
      NUM_ALIGNMENTS="$2"
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

# Required Args check:
# --------------------
if [ -z "${QUERY}" ] || [ -z "${DATABASE}" ] || [ -z ${HOSTNAME_PREFIX} ]; then
    usage
fi

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

if [ -z ${GAP_OPEN} ]; then
   echo "Warning: -d not set, setting to default to current directory"
   GAP_OPEN=10
fi

if [ -z ${GAP_EXTEND} ]; then
   echo "Warning: -d not set, setting to default to current directory"
   GAP_EXTEND=1
fi

if [ -z ${NUM_ALIGNMENTS} ]; then
   echo "Warning: -d not set, setting to default to current directory"
   NUM_ALIGNMENTS=500
fi

# Args correctness checks
# -----------------------

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

# Load JAVA
module load Java/11.0.2

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
SPARK_MASTER_HOSTNAME=$(ls ${SLURM_JOB_DIR}/logs | grep -o "${HOSTNAME_PREFIX}[0-9]*" | head -n 1)
echo ${SPARK_MASTER_HOSTNAME}
SPARK_MASTER_ADDRESS="spark://${SPARK_MASTER_HOSTNAME}:7077"
echo ${SPARK_MASTER_ADDRESS}

# Partitions IDs Prefix
partitionsIDs="_partitionsIDs"
dbLen=$(head -n 1 "${DATABASE}/database.dbs")
numSeq=$(tail -n 1 "${DATABASE}/database.dbs")
outfmt=8 # Hard coded for now since only tabular is currently supported

# Submit Spark job to perform blast search
/home/karimy/spark-2.2.0-bin-hadoop2.6/bin/spark-submit --master ${SPARK_MASTER_ADDRESS} --verbose --conf "spark.local.dir=/home/karimy/tmpSpark" --conf "spark.network.timeout=3600" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=120g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=100g" --conf "spark.driver.memory=4g" --conf "spark.executor.memory=4g" --class SparkLeBLASTSearch target/scala-2.11/simple-project_2.11-1.0.jar "${DATABASE}${partitionsIDs}" ${QUERY} ${DATABASE} "/home/karimy/SparkLeBLAST/blastSearchScript" ${dbLen} ${numSeq} ${GAP_OPEN} ${GAP_EXTEND} ${outfmt} ${NUM_ALIGNMENTS}
