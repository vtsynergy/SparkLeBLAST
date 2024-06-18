#CLEARALL=no ./slurm_sub.sh nt HPEC_sample.fa 3 long 48:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run
#CLEARALL=no ./slurm_sub.sh nt HPEC_sample.fa 5 long 48:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run
#CLEARALL=no ./slurm_sub.sh nt HPEC_sample.fa 9 medium 12:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run
CLEARALL=no ./slurm_sub.sh nt HPEC_sample.fa 17 medium 12:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run
#CLEARALL=no ./slurm_sub.sh nt HPEC_sample.fa 33 medium 12:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run
#CLEARALL=no ./slurm_sub.sh nt HPEC_sample.fa 65 large 08:00:00 /lustre/scratch/rprabhu/sparkleblast_data
#CLEARALL=no ./slurm_sub_dep.sh nt HPEC_sample.fa 129 all-nodes 04:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run slurm-128_node_nt_database_run.out 198378

#./slurm_sub.sh nt HPEC_sample.fa 33 medium 12:00:00 /lustre/scratch/rprabhu/sparkleblast_data/nt_run
