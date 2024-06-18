#!/bin/bash

previous_job_id=""
for (( i = 1; i <= 10; i++ )); do
    if [ ! -z "$previous_job_id" ]; then
            CLEARALL=no ./slurm_sub_dep.sh nt HPEC_sample.fa 2 extended 60:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run slurm-1_node_nt_database_run${i}.out $previous_job_id
	    sleep 5
    else
	    CLEARALL=no ./slurm_sub_dep.sh nt HPEC_sample.fa 2 extended 60:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run slurm-1_node_nt_database_run${i}.out
	    sleep 5
    fi
    previous_job_id=$(cat job_id.txt)
done
