#!/bin/bash
rm -rf  hosts master_success
NPROC=2
PJSUB_ARGS=(
  -L elapse=1:30:00
  -L node=${NPROC}
  --mpi proc=${NPROC}
  --interact
  --sparam wait-time=60
  -x PJM_LLIO_GFSCACHE=/vol0004
  -x SINGULARITY_TMPDIR=/local
  -g ra000012
  --llio localtmp-size=20Gi
  -L jobenv=singularity
)
pjsub  ${PJSUB_ARGS[@]}
