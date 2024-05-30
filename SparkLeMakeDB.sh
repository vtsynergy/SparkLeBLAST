#!/bin/bash

usage() { echo "Usage: ./SparkLeMakeDB.sh -i /path/to/raw/db -t /path/to/output/db -dbtype (prot or nucl) -o parse_options (T or F) -p <num_partitions> -m <spark_master_address> -w <num_workers> -time <Time in integer minutes> -h hostname_prefix -d /path/to/logs/dir (default current dir)" 1>&2; exit 1; }

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
    -dbtype|--dbtype)
      DB_TYPE="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--partitioms)
      PARTITIONS="$2"
      shift # past argument
      shift # past value
      ;;
    -m|--masteraddress)
      MASTER_ADDRESS="$2"
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
if [ -z "${INPUT_PATH}" ] || [ -z "${OUTPUT_PATH}" ]; then
    usage
fi

if [ -z ${HOSTNAME_PREFIX} ] && [ -z ${MASTER_ADDRESS} ]; then
    echo "Error: Please specify either hostname prefix using --hostnameprefix or a Spark master address using --masteraddress"
    exit 1
fi

if [ -d "${OUTPUT_PATH}" ]; then
    echo "Error: Directory ${OUTPUT_PATH} Already Exists"
    exit 1
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

if [ -z ${DB_TYPE} ]; then
   echo "Warning: -dbtype not set, setting to default to prot "
   DB_TYPE="prot"
fi

# Args correctness checks
# -----------------------

if [ -z ${SPARK_SLURM_PATH} ] && [ -z ${MASTER_ADDRESS} ]; then
    echo "Error: Please set SPARK_SLURM_PATH env. variable or --masteraddress if a Spark cluster is already up"
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
echo "MASTER_ADDRESS   = ${MASTER_ADDRESS}"

# Load JAVA
module load Java/11.0.2

if [ -z ${MASTER_ADDRESS} ]; then
  # Launch Spark Cluster using spark-slurm
  CLUTER_ID=$(${SPARK_SLURM_PATH} start -t ${TIME} ${WORKERS} | awk '{print $6}')
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
# while [ ! -d ${SLURM_JOB_DIR} ]; do
#   sleep 1;
# done

  # Wait for job to be running
  echo "Waiting for SLURM job to start"
  status=$(squeue -j ${SLURM_JOB_ID} | tail -n 1 | awk '{print $5}')
  while [[ "${status}" != "R"  ]]; do
    sleep 1;
    status=$(squeue -j ${SLURM_JOB_ID} | tail -n 1 | awk '{print $5}');
  done
  echo "SLURM job now running"

  echo "Waiting for job directory"
  # Wait for job directory
  while [ ! -d ${SLURM_JOB_DIR} ]; do
    sleep 1;
  done

  # Get Spark Master Hostname and construct Master Address
  echo "Waiting for Spark Master"
  SPARK_MASTER_HOSTNAME=$(ls ${SLURM_JOB_DIR}/logs | grep -o "${HOSTNAME_PREFIX}[0-9]*" | head -n 1)
  while [[ -z ${SPARK_MASTER_HOSTNAME} ]]; do
      SPARK_MASTER_HOSTNAME=$(ls ${SLURM_JOB_DIR}/logs | grep -o "${HOSTNAME_PREFIX}[0-9]*" | head -n 1)
  done

  echo "Launching ..."
  echo ${SPARK_MASTER_HOSTNAME}
  SPARK_MASTER_ADDRESS="spark://${SPARK_MASTER_HOSTNAME}:7077"
  echo ${SPARK_MASTER_ADDRESS}

else
  SPARK_MASTER_ADDRESS=${MASTER_ADDRESS}
fi

TOTAL_SIZE=$(du -sb ${INPUT_PATH})
echo "---------------------DEBUGGING---------------------"
echo "From inside SparkLeMakeDB.sh....."
echo "Output path = ${OUTPUT_PATH}"
echo "NCBI BLAST PATH = ${NCBI_BLAST_PATH}"
echo "SLB WORKDIR = ${SLB_WORKDIR}"
echo "TOTAL SIZE = ${TOTAL_SIZE}"
echo "---------------------DEBUGGING---------------------"

# Submit Spark job to format the BLAST DB
${SPARK_HOME}/bin/spark-submit --master ${SPARK_MASTER_ADDRESS} --verbose --conf "spark.executor.instances=1" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=30g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=30g" --conf "spark.driver.memory=29g" --conf "spark.executor.memory=29g" --class SparkLeMakeDB ${SLB_WORKDIR}/target/scala-2.11/simple-project_2.11-1.0.jar ${PARTITIONS} ${INPUT_PATH} "${SLB_WORKDIR}/formatdbScript" ${OUTPUT_PATH} ${NCBI_BLAST_PATH} ${SLB_WORKDIR} ${TOTAL_SIZE}; # ${DB_TYPE};
echo $
# Cancel SLURM Job
if [ ! -z ${SPARK_SLURM_PATH} ]; then
    HOST_NUMBER=$(echo ${SPARK_MASTER_ADDRESS} | grep -o "[0-9]*" | head -n 1)
    echo ${HOST_NUMBER}
    JOB_ID=$(squeue -u ${USER} | grep ${HOST_NUMBER} | awk '{print $1}')
    scancel ${JOB_ID}
fi
