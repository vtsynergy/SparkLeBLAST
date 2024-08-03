#!/bin/bash
#PJM -g ra000012
#PJM -x PJM_LLIO_GFSCACHE=/vol0004
#PJM -L elapse=10:00
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

seg_dir() { echo "$(realpath "${OUT_DIR}")/seg$1"; }
seg_tmp_dir() { echo "$(seg_dir "$1")/tmp"; }
seg_mpi_dir() { echo "$(seg_dir "$1")/out"; }
seg_of_proc() { echo "$(seg_mpi_dir "$1")/mpi"; }
seg_hosts_file() { echo "$(seg_tmp_dir "$1")/hosts"; }
seg_vcoord_file() { echo "$(seg_tmp_dir "$SEG")/vcoord"; }

# seg_master_file() { echo "$(seg_tmp_dir "$SEG")/master"; }
# seg_run_dir() { echo "$(seg_tmp_dir "$SEG")/run"; }
# seg_log_dir() { echo "$(seg_tmp_dir "$SEG")/log"; }
# seg_work_dir() { echo "$(seg_tmp_dir "$SEG")/work"; }

mkdirs () { 
  DIRS=(
  "$(seg_tmp_dir "$SEG")"
  "$(seg_mpi_dir "$SEG")"
  # "$(seg_run_dir "$SEG")"
  # "$(seg_log_dir "$SEG")"
  # "$(seg_work_dir "$SEG")"
  )
  mkdir -p "${DIRS[@]}" 
}

mkvcoord () { 
  yes "(${SEG})" | head -n $group_size > "$(seg_vcoord_file "${SEG}")"
}

mpi_with_args () {
  MPI_ARGS=(
  -of-proc "$(seg_of_proc "$SEG")" 
  --vcoordfile "$(seg_vcoord_file "${SEG}")"
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

singularity_instance_start () {
  SINGULARITY_ARGS=(
    --bind "$(seg_run_dir "$1"):/run"
    --bind "$(seg_log_dir "$1"):/opt/spark-2.2.0-bin-hadoop2.6/logs"
    --bind "$(seg_work_dir "$1"):/opt/spark-2.2.0-bin-hadoop2.6/work"
    --bind "$(seg_hosts_file "$1"):/etc/hosts"
    --bind data:/tmp/data
    --disable-cache
    --cleanenv
    sparkleblast_latest.sif
    spark-process
  )
  singularity instance start "${SINGULARITY_ARGS[@]}"
}

start_master () {
  singularity_instance_start "$1"
  singularity exec --env SPARK_MASTER_HOST="$(hostname)" instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-master.sh
  sleep 5
  hostname > "$(seg_master_file "$1")"
}

start_worker () {
  while [ ! -e "$(seg_master_file "$1")" ]; do sleep 1; done
  master_node=$(head -n 1 "$(seg_master_file "$1")")
  singularity_instance_start "$1"
  sleep 5
  master_url="spark://${master_node}:7077"
  singularity exec instance://spark-process /opt/spark-2.2.0-bin-hadoop2.6/sbin/start-slave.sh "${master_url}"
  while [ -e "$(seg_master_file "$1")" ]; do sleep 1; done
}

start_cluster () {
  if [ "${PMIX_RANK}" -eq "0" ]; then
    start_master "$1"
  else
    start_worker "$1"
  fi
}

group_size=$(( PJM_MPI_PROC / PJM_NODE ))
for SEG in $(seq 0 $(( NUM_SEGMENTS - 1 ))); do
  mkdirs
  mkvcoord
done
split_query
for SEG in $(seq 0 $(( NUM_SEGMENTS - 1 ))); do
  mpi_with_args ./gatherhosts_ips "$(seg_hosts_file "$SEG")"
done
for SEG in $(seq 0 $(( NUM_SEGMENTS - 1 ))); do
  mpi_with_args multi_start.sh "$(seg_tmp_dir "$SEG")"
  # bash -x ./run_spark_jobs.sh ${DBFILE} ${QUERYFILE}
  # # mpiexec -of-proc \${OF_PROC} ./stop_spark_cluster.sh &
  # rm -rf master_success-\${PJM_JOBID}
done
wait
