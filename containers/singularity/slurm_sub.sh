#!/bin/bash

#set -x

DBFILE=$1
QUERYFILE=$2
export NPROC=$3
ALLOCATION=$4
ELAPSE=${5:-30:00}
DATAPATH=${6:-"data"}


USAGE="$0 \${NPROC}"
if [ -z ${NPROC} ]; then
  echo "NPROC not set!"
  echo ${USAGE}
  exit 1
fi
if [ ! -f ${DATAPATH}/${DBFILE} ]; then
    echo "Could not find ${DATAPATH}/${DBFILE}"
    echo ${USAGE}
    exit 1;
fi
if [ ! -f ${DATAPATH}/${QUERYFILE} ]; then
    echo "Could not find ${DATAPATH}/${QUERYFILE}"
    echo ${USAGE}
    exit 1;
fi

if [ -z "$ALLOCATION" ]; then
  echo "Error: Allocation is not specified."
  exit 1
fi

if [ ${NPROC} -gt 384 ]; then
  RSCGRP=large;
else
  RSCGRP=small;
fi

OUTPUT_DIR=output

NAME=sparkle-${NPROC}

SLURM_ARGS=(
 -N ${NPROC}
 -p ${ALLOCATION}
 -A pn_cis240131
 --exclusive
 --time ${ELAPSE}
 --job-name "$((NPROC - 1))_Node_Run"
--output="slurm-$((NPROC - 1))_node_${DBFILE}_database_run.out"
)

if [[ "${CLEARALL^^}" =~ ^(YES|ON|TRUE)$ ]]; then 
  # must be outside pjsub
  rm -rf output run log work ${DATAPATH}/makedb_out ${DATAPATH}/search_out
fi

mkdir -p ${OUTPUT_DIR}
TMPFILE=$(mktemp)
cat > $TMPFILE << EOF
#!/bin/bash

module load openmpi/gcc13.1.0/4.1.5

OF_PROC=${OUTPUT_DIR}/\${SLURM_JOBID}-${NAME}/mpi

mkdir -p log run work \$(dirname \${OF_PROC})

# Record the start time
START_TIME=\$(date +%s)

mpiexec --output-filename \${OF_PROC} --map-by ppr:1:node:pe=48 ./gatherhosts_ips hosts-\${SLURM_JOBID}
mpiexec --output-filename \${OF_PROC} --map-by ppr:1:node:pe=48 ./start_spark_cluster.sh ${DATAPATH} &
bash ./run_spark_jobs.sh ${DBFILE} ${QUERYFILE} ${DATAPATH}

# Record the end time
END_TIME=\$(date +%s)

# Calculate the duration
DURATION=\$((END_TIME - START_TIME))

# Output the duration
echo "Job started at: \$(date -d @\$START_TIME)"
echo "Job ended at: \$(date -d @\$END_TIME)"
echo "Job duration: \$DURATION seconds"


rm -rf master_success-\${SLURM_JOBID}
echo SLURM_SUB IS DONE.
EOF

sbatch  ${SLURM_ARGS[@]} $TMPFILE 
