#!/bin/bash
#SBATCH --job-name=build-singularity
#SBATCH --nodes=4           
#SBATCH --account=hpcbigdata2
#SBATCH --time=1:00:00       
#SBATCH --nodes=1            
#SBATCH --gid=ra000012       
#SBATCH --tmp=20GiB          
#SBATCH --jobenv=singularity 
#SBATCH --export=ALL         
#SBATCH --chdir=/local       

# export TMPDIR=/tmp
singularity build --fakeroot sparkleblast_latest.sif sparkleblast_latest_x86.def

echo "DONE"
