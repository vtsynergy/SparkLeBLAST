#!/bin/bash
rm -rf  hosts master_success
NPROC=2
PJSUB_ARGS=(
  -L elapse=1:30:00
  -L node="${NPROC}"
  # -L freq=2200 -L throttling_state=0 -L issue_state=0 -L ex_pipe_state=0 -L eco_state=0 -L retention_state=0
  --mpi proc="${NPROC}"
  --interact
  --sparam wait-time=60
  -x PJM_LLIO_GFSCACHE=/vol0004
  -x SINGULARITY_TMPDIR=/local
  -g ra000012
  --llio localtmp-size=20Gi
  -L jobenv=singularity
)
pjsub  "${PJSUB_ARGS[@]}"
