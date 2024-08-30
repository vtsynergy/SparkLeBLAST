#!/bin/bash
  
previous_job_id=""
for (( i = 7; i <= 10; i++ )); do
if [ ! -z "$previous_job_id" ]; then
 ./slurm_sub_dep.sh nt test_sample_1.fa 2 01:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run slurm-1_node_nt_database_run${i}.out $previous_job_id
else
 ./slurm_sub_dep.sh nt test_sample_1.fa 2 01:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run slurm-1_node_nt_database_run${i}.out
fi
previous_job_id=$(cat job_id.txt)
done
