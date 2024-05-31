#!/bin/bash

SINGULARITY_ARGS=(
  --no-home
  # --bind hosts:/etc/hosts
  --bind data:/tmp/data
)

#singularity exec ${SINGULARITY_ARGS[@]} sparkleblast_latest.sif /bin/bash
singularity exec sparkleblast_latest.sif /bin/bash
