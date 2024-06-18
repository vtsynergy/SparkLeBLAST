#!/bin/bash
#SBATCH --job-name=build-singularity
#SBATCH --time=4:00:00       
#SBATCH --nodes=1            
#SBATCH -p short

module load gcc/13.2.0
singularity build --remote sparkleblast_latest.sif sparkleblast_latest.def

echo "DONE"
