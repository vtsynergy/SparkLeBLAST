#!/bin/bash
#SBATCH --job-name=build-singularity
#SBATCH --account=pn_cis240131
#SBATCH --time=4:00:00       
#SBATCH --nodes=1            
#SBATCH -p short
singularity build --remote sparkleblast_latest.sif sparkleblast_latest.def

echo "DONE"
