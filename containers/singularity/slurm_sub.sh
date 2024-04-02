#!/bin/bash

#set -x

DBFILE=$1
QUERYFILE=$2
export NPROC=$3
ELAPSE=${4:-30:00}

USAGE="$0 \${NPROC}"
if [ -z ${NPROC} ]; then
  echo "NPROC not set!"
  echo ${USAGE}
  exit 1
fi
if [ ! -f data/${DBFILE} ]; then
    echo "Could not find data/${DBFILE}"
    echo ${USAGE}
    exit 1;
fi
if [ ! -f data/${QUERYFILE} ]; then
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
 -p short
 -A pn_cis240131
 --exclusive
 --time 01:00:00

)

if [[ "${CLEARALL^^}" =~ ^(YES|ON|TRUE)$ ]]; then 
  # must be outside pjsub
  rm -rf output run log work data/makedb_out data/search_out
fi

mkdir -p ${OUTPUT_DIR}
TMPFILE=$(mktemp)
cat > $TMPFILE << EOF
#!/bin/bash
module reset
module load openmpi/gcc13.1.0/4.1.5
module load singularity/4.0.2
OF_PROC=${OUTPUT_DIR}/\${SLURM_JOBID}-${NAME}/mpi

mkdir -p log run work \$(dirname \${OF_PROC})
mpiexec --output-filename \${OF_PROC} ./gatherhosts_ips hosts-\${SLURM_JOBID}
mpiexec --output-filename \${OF_PROC} ./start_spark_cluster.sh &
bash ./run_spark_jobs.sh ${DBFILE} ${QUERYFILE}
rm -rf master_success-\${SLURM_JOBID}
echo FSUB IS DONE
EOF

sbatch ${SLURM_ARGS[@]} $TMPFILE 
# DBFILE=non-rRNA-reads.fa
# Galaxy25-\[Geobacter_metallireducens.fasta\].fasta
# QUERYFILE=sample_text.fa
