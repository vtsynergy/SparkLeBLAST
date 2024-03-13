#!/bin/bash
#PJM -g ra000012
#PJM -x PJM_LLIO_GFSCACHE=/vol0004
#PJM -L elapse=1:00
#PJM -L node=2
#PJM --mpi proc=8
#PJM -o ttiny/%j.stdout
#PJM -e ttiny/%j.stderr

# shellcheck disable=2034
# echo PJM_STDOUT_PATH $PJM_STDOUT_PATH
# echo PJM_STDERR_PATH $PJM_STDERR_PATH

set -x
PLE_MPI_STD_EMPTYFILE="off"

OUT_DIR=${PJM_STDOUT_PATH%.*} # ttiny/123
mkdir -p "${TMP_FILES}"

# $PJM_NODE $PJM_MPI_PROC
GROUP_SIZE=$(( PJM_MPI_PROC / PJM_NODE ))
NUM_SEGMENTS=${PJM_NODE}

mkvcoord () { yes "(${seg})" | head -n $GROUP_SIZE > "${vcoord}"; }

segmpiexec () { mpiexec -of-proc "${of_proc}" --vcoordfile "${vcoord}" "$@"; }

each_group() {
  vcoord=${seg_tmp_dir}/vcoord
  mkvcoord
  segmpiexec hostname
}

for seg in $(seq 0 $(( NUM_SEGMENTS - 1 ))); do
  seg_dir=${OUT_DIR}/seg${seg}
  seg_tmp_dir="${seg_dir}/tmp"
  of_proc=${seg_dir}/out/mpi
  mkdir -p "${seg_tmp_dir}" "$(dirname "${of_proc}")"
  ./split_query.sh
  each_group
done

