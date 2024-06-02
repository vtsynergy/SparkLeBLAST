#!/bin/bash
#SBATCH --job-name=compile-ncbi
#SBATCH --account=pn_cis240131
#SBATCH --time=4:00:00       
#SBATCH --nodes=1            
#SBATCH -p short

tar -xvzf ncbi-blast-2.13.0+-src.tar.gz
cd ncbi-blast-2.13.0+-src/c++
./configure
make -j4
echo "DONE COMPILE NOW BUILDING IMAGE"
