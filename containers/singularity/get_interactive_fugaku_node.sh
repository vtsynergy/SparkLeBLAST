#!/bin/bash
cat fsub.sh; rm -rf  hosts master_success; pjsub --interact --sparam wait-time=60 -x PJM_LLIO_GFSCACHE=/vol0004 -g ra000012 --llio localtmp-size=10Gi -L "node=2,elapse=2:00:00,jobenv=singularity" --mpi proc=2
