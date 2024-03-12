#!/bin/bash

#PJM -g ra000012
#PJM -x PJM_LLIO_GFSCACHE=/vol0004
#PJM -L elapse=1:00
#PJM -L node=2
#PJM --mpi proc=8
#PJM -o ttiny/%j.stdout
#PJM -e ttiny/%j.stderr

# echo PJM_STDOUT_PATH $PJM_STDOUT_PATH
# echo PJM_STDERR_PATH $PJM_STDERR_PATH

set -x
PLE_MPI_STD_EMPTYFILE="off"

OUT_DIR=${PJM_STDOUT_PATH%.*} # ttiny/123
TMP_FILES="${OUT_DIR}/tmpfiles" # ttiny/123/tmpfiles
mkdir -p ${TMP_FILES}

# $PJM_NODE $PJM_MPI_PROC
GROUP_SIZE=$(( ${PJM_MPI_PROC} / ${PJM_NODE} ))
NUM_GROUPS=${PJM_NODE}
for gid in $(seq 0 $(( ${NUM_GROUPS} - 1 ))); do
  grp_tmp_files="${TMP_FILES}/grp_${gid}" # ttiny/123/tmpfiles/grp-0
  mkdir -p ${grp_tmp_files}
  vcord=${grp_tmp_files}/vcord
  rm -f ${vcord}
  yes \(${gid}\) | head -n $GROUP_SIZE > ${vcord}
  of_proc=${OUT_DIR}/mpi/grp_${gid}/
  # mkdir -p $(dirname ${of_proc})
  mpiexec -of-proc ${of_proc} --vcoordfile ${vcord} hostname
done

