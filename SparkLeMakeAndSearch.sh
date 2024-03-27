#!/bin/bash


# module load jdk

# masterAddress="spark://ca015.ca.arc.internal:7077"
# dbPath="/work/cascades/karimy/blastDB/nr"
# numPartitions=1000
# dbName="/work/cascades/karimy/blastDB/nr_1000_indexed"
# /home/karimy/spark-2.2.0-bin-hadoop2.6/bin/spark-submit --conf "spark.local.dir=/home/karimy/tmpSpark" --conf "spark.network.timeout=3600" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=120g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=100g" --master $masterAddress --driver-memory 100g --executor-memory 100g --class MakeDB target/scala-2.11/simple-project_2.11-1.0.jar $numPartitions $dbPath "/home/karimy/SparkLeBLAST/formatdbScript" $dbName;

usage() { echo "Usage: ./SparkLeMakeDB.sh -i /path/to/raw/db -t /path/to/output/db -q /path/to/query -dbtype (prot or nucl) -o parse_options (T or F) -p <num_partitions> -w <num_workers> -time <Time in integer minutes> -h hostname_prefix -d /path/to/logs/dir (default current dir)" 1>&2; exit 1; }

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
    -q|--query)
      QUERY="$2"
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
if [ -z "${INPUT_PATH}" ] || [ -z "${OUTPUT_PATH}" ] || [ -z ${HOSTNAME_PREFIX} ] || [ -z ${QUERY} ]; then
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

if [ -z ${DB_TYPE} ]; then
   echo "Warning: -dbtype not set, setting to default to prot "
   DB_TYPE="prot"
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

# Submit Spark job to format the BLAST DB
echo "Formatting BLAST DB"
"${SPARK_HOME}"/bin/spark-submit --master ${SPARK_MASTER_ADDRESS} --verbose --conf "spark.local.dir=${SPARK_LOCAL_DIRECTORY}" --conf "spark.network.timeout=3600" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=220g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=220g" --conf "spark.driver.memory=192g" --conf "spark.executor.memory=192g" --executor-cores 1 --class SparkLeMakeDB "${COMPILED_SCALA_DIRECTORY}" ${PARTITIONS} ${INPUT_PATH} "${SLB_WORKDIR}/formatdbScript" ${OUTPUT_PATH} ${DB_TYPE} &> output_makedb_${WORKERS};
echo "DB Formatting Done"

# Copy to VAST
# time cp -r /localscratch

# Partitions IDs Prefix
DATABASE=${OUTPUT_PATH}
partitionsIDs="_partitionsIDs"
dbLen=$(head -n 1 "${DATABASE}/database.dbs")
numSeq=$(tail -n 1 "${DATABASE}/database.dbs")
outfmt=6 # Hard coded for now since only tabular is currently supported

# Temp variables (In the future, all BLAST parameters will be passed via the blastSearchScript script
GAP_OPEN=10
GAP_EXTEND=1
NUM_ALIGNMENTS=10


# Submit Spark job to perform blast search
echo "Starting BLAST Search"
"${SPARK_HOME}"/bin/spark-submit --master ${SPARK_MASTER_ADDRESS} --verbose --conf "spark.local.dir=${SPARK_LOCAL_DIRECTORY}" --conf "spark.network.timeout=3600" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=120g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=100g" --conf "spark.driver.memory=4g" --conf "spark.executor.memory=4g" --class SparkLeBLASTSearch "${COMPILED_SCALA_DIRECTORY}" "${DATABASE}${partitionsIDs}" ${QUERY} ${DATABASE} "${SLB_WORKDIR}/blastSearchScript_2.12_blastn" ${dbLen} ${numSeq} ${GAP_OPEN} ${GAP_EXTEND} ${outfmt} ${NUM_ALIGNMENTS} &> output_balst_search_${WORKERS}
echo "BLAST Search Done"

HOST_NUMBER=$(echo ${SPARK_MASTER_ADDRESS} | grep -o "[0-9]*" | head -n 1)
echo ${HOST_NUMBER}
JOB_ID=$(squeue -u ${USER} | grep ${HOST_NUMBER} | awk '{print $1}')
scancel ${JOB_ID}

# Remove partitions
rm -rf ${DATABASE}
rm -rf ${DATABASE}_formatting_logs
rm -rf ${DATABASE}_partitionsIDs

# Move final output
# mv finalOutput /fastscratch/karimy/finalOutput_${WORKERS}
# mv finalOutputByQuery /fastscratch/karimy/finalOutputByQuery_${WORKERS}
# mv finalOutputSorted /fastscratch/karimy/finalOutputSorted_${WORKERS}
