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

# $PJM_NODE $PJM_MPI_PROC
if [[ "$PJM_ENVIRONMENT" = "BATCH" ]]; then
  PLE_MPI_STD_EMPTYFILE="off"
  NUM_SEGMENTS=${PJM_NODE}
  OUT_DIR=$(realpath "${PJM_STDOUT_PATH%.*}") # ttiny/123
else
  NUM_SEGMENTS=3
  OUT_DIR=$(realpath ./foobar)
fi
DB_FILE=$(realpath data/non-rRNA-reads.fa)
QUERY_FILE=$(realpath data/g50.fasta)

seg_dir() { echo "$(realpath "${OUT_DIR}")/seg${1}"; }
seg_tmp_dir() { echo "$(seg_dir "$1")/tmp"; }
seg_mpi_dir() { echo "$(seg_dir "$1")/out"; }
seg_of_proc() { echo "$(seg_mpi_dir "$1")/mpi"; }
seg_hosts_file() { echo "$(seg_tmp_dir "$1")/hosts"; }

mkdirs () { 
  mkdir -p "$(seg_tmp_dir "$SEG")" "$(seg_mpi_dir "$SEG")"
}

mkvcoord () { 
  vcoord="$(seg_tmp_dir "$SEG")/vcoord"
  yes "(${SEG})" | head -n $group_size > "${vcoord}"
}

mpi_with_args () {
  MPI_ARGS=(
  -of-proc "$(seg_of_proc "$SEG")" 
  --vcoordfile "${vcoord}"
  )
  mpiexec "${MPI_ARGS[@]}" "$@"
}

split_query () {
  pushd "$OUT_DIR" || exit
  num_lines=$(wc -l "$QUERY_FILE" | cut -f1 -d \ )
  # num_lines=CEIL(num_lines / NUM_SEGMENTS)
  num_lines=$(( ( num_lines + NUM_SEGMENTS - 1) / NUM_SEGMENTS ))
  if [ $(( num_lines % 2 )) -eq 1 ]; then num_lines=$(( num_lines + 1 )); fi
  suffix="-$(basename "$QUERY_FILE")-numseg${NUM_SEGMENTS}"
  split -l $num_lines "$QUERY_FILE" --additional-suffix="$suffix"
  mapfile -t < <(ls ./*"${suffix}"*)
  echo "num files: ${#MAPFILE[@]}"
  for i in "${!MAPFILE[@]}"; do
    echo "$i ${MAPFILE[$i]}"
    seg_query_file[i]="$(seg_dir "$i")/$(basename "${MAPFILE[$i]}")"
    mv "${MAPFILE[$i]}" "${seg_query_file[$i]}"
  done
  popd || exit
}

group_size=$(( PJM_MPI_PROC / PJM_NODE ))
for SEG in $(seq 0 $(( NUM_SEGMENTS - 1 ))); do
  mkdirs
  mkvcoord
done
split_query
for SEG in $(seq 0 $(( NUM_SEGMENTS - 1 ))); do
  mpi_with_args ./gatherhosts_ips "$(seg_hosts_file "$SEG")"
  # mpiexec -of-proc \${OF_PROC} ./start_spark_cluster.sh &
  # bash -x ./run_spark_jobs.sh ${DBFILE} ${QUERYFILE}
  # # mpiexec -of-proc \${OF_PROC} ./stop_spark_cluster.sh &
  # rm -rf master_success-\${PJM_JOBID}
done

