#!/bin/bash

#set -x

DBFILE=$1
QUERYFILE=$2
export NPROC=$3
ELAPSE=${4:-30:00}
DATAPATH=${5:-"data"}

USAGE="$0 \${NPROC}"
if [ -z ${NPROC} ]; then
  echo "NPROC not set!"
  echo ${USAGE}
  exit 1
fi
if [ ! -f ${DATAPATH}/${DBFILE} ]; then
    echo "Could not find data/${DBFILE}"
    echo ${USAGE}
    exit 1;
fi
if [ ! -f ${DATAPATH}/${QUERYFILE} ]; then
    echo "Could not find data/${QUERYFILE}"
    echo ${USAGE}
    exit 1;
fi
if email=$(git config --get user.email); then
    email_args="-m b,e --mail-list ${email}"
else
    echo "$0 WARNING: git email not set!"
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
 -p debug
 --exclusive
 --time ${ELAPSE}
 --job-name "$((NPROC - 1))_Node_Run"
 --output="slurm-$((NPROC - 1))_node_${DBFILE}_database_run.out"
 --reservation=request_ticket_58222
)

if [[ "${CLEARALL^^}" =~ ^(YES|ON|TRUE)$ ]]; then 
  # must be outside pjsub
  rm -rf output run log work ${DATAPATH}/makedb_out ${DATAPATH}/search_out
fi

mkdir -p ${OUTPUT_DIR}
TMPFILE=$(mktemp)
cat > $TMPFILE << EOF
#!/bin/bash
module load GCC/11.3.0
module load OpenMPI/4.1.4
module load WebProxy

OF_PROC=${OUTPUT_DIR}/\${SLURM_JOBID}-${NAME}/mpi

mkdir -p log run work \$(dirname \${OF_PROC})

# Record the start time
START_TIME=\$(date +%s)

mpiexec --output-filename \${OF_PROC} --map-by ppr:1:node:pe=96 ./gatherhosts_ips hosts-\${SLURM_JOBID}
mpiexec --output-filename \${OF_PROC} --map-by ppr:1:node:pe=96 ./start_spark_cluster.sh ${DATAPATH} &
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
# DBFILE=non-rRNA-reads.fa
# Galaxy25-\[Geobacter_metallireducens.fasta\].fasta
# QUERYFILE=sample_text.fa
