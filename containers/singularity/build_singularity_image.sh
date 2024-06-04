#!/bin/bash
#SBATCH --job-name=build-singularity
#SBATCH --time=5:00:00       
#SBATCH --nodes=1            
#SBATCH -p cpu
#SBATCH --mem=3072M

module load WebProxy
module load GCC/13.2.0
singularity build --fakeroot sparkleblast_latest.sif sparkleblast_latest.def

echo "DONE"
