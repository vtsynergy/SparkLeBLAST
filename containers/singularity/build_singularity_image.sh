#!/bin/bash
#SBATCH --job-name=build-singularity
#SBATCH --time=4:00:00       
#SBATCH --nodes=1            
#SBATCH -p cpu
#SBATCH --mem=2048M

module load WebProxy
singularity build --fakeroot sparkleblast_latest.sif sparkleblast_latest.def

echo "DONE"
