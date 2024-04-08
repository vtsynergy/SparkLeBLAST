#!/bin/bash

#set -x

DBFILE=$1
QUERYFILE=$2
export NPROC=$3
ELAPSE=${4:-30:00}
TYPE=$5

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


OUTPUT_DIR=output
NAME=sparkle-${NPROC}
PJSUB_ARGS=(
  -N ${NAME}
  -S # -j
  -o ${OUTPUT_DIR}/%j-${NAME}.stdout
  -e ${OUTPUT_DIR}/%j-${NAME}.stderr
  --spath ${OUTPUT_DIR}/%j-${NAME}.stat
  -x PJM_LLIO_GFSCACHE=/vol0004
  -x SINGULARITY_TMPDIR=/local
  -g ra000012
  # --llio localtmp-size=10Gi
  -L rscgrp=${RSCGRP}
  -L node=${NPROC}
  -L elapse=${ELAPSE}
  -L jobenv=singularity
  --mpi proc=${NPROC}
  ${email_args}
)

SLURM_ARGS=(
 -N ${NPROC}
 -p p100_dev_q
 -A hpcbigdata2
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
module load OpenMPI
module load containers/singularity
OF_PROC=${OUTPUT_DIR}/\${SLURM_JOBID}-${NAME}/mpi

rm -rf  hosts master_success
mkdir -p log run hosts work \$(dirname \${OF_PROC})
mpiexec ./gatherhosts_ips ./hosts/hosts-\${SLURM_JOBID}
mpiexec ./start_spark_cluster.sh &
bash ./run_spark_jobs_arc.sh ${DBFILE} ${QUERYFILE} ${TYPE}
# mpiexec -of-proc \${OF_PROC} ./stop_spark_cluster.sh &
rm -rf master_success
echo FSUB IS DONE
EOF

sbatch ${SLURM_ARGS[@]} $TMPFILE 
# DBFILE=non-rRNA-reads.fa
# Galaxy25-\[Geobacter_metallireducens.fasta\].fasta
# QUERYFILE=sample_text.fa
