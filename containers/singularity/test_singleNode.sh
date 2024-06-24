

#!/bin/bash

  

previous_job_id=""

for (( i = 1; i <= 10; i++ )); do

if [ ! -z "$previous_job_id" ]; then

 ./slurm_sub_dep.sh nt HPEC_sample.fa 2 01:00:00 /scratch/user/u.rp167879/sparkleblast_data slurm-1_node_48_threads_nt_database_run${i}.out $previous_job_id

else

 ./slurm_sub_dep.sh nt HPEC_sample.fa 2 01:00:00 /scratch/user/u.rp167879/sparkleblast_data slurm-1_node_48_threads_nt_database_run${i}.out

fi

sleep 5

previous_job_id=$(cat job_id.txt)

done
