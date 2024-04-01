#!/bin/bash
#SBATCH --job-name=build-singularity
#SBATCH --nodes=4           
#SBATCH --account=pn_cis240131
#SBATCH --time=1:00:00       
#SBATCH --nodes=1            
#SBATCH --gid=ra000012       
#SBATCH --tmp=20GiB          
#SBATCH --jobenv=singularity 
#SBATCH --export=ALL         
#SBATCH --chdir=/local       

singularity build --fakeroot sparkleblast_latest.sif sparkleblast_latest.def

echo "DONE"
