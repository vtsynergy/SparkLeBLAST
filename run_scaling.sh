#!/bin/bash

# 128 nodes, preemptable_q
export SPARK_SLURM_PATH=/home/karimy/spark-slurm/spark_normal_full_node
# ./SparkLeMakeAndSearch.sh -i /fastscratch/karimy/blastDB/nr -t /fastscratch/karimy/blastDB/nr_formatted -q /fastscratch/karimy/blastDB/GeobacterMetallireducens.fasta -o T  -dbtype prot -p 128 -w 128 -time 480 -h tc -d /fastscratch/karimy/SparkLogs

# Other configs, normal_q
# export SPARK_SLURM_PATH=/home/karimy/spark-slurm/spark

for i in 4; do
./SparkLeMakeAndSearch.sh -i /fastscratch/karimy/blastDB/uniprot_sprot.fasta -t /localscratch/uniprot_sprot_formatted -q /fastscratch/karimy/blastDB/geobacter_8_partitions/GeobacterMetallireducens_8.fasta -o T  -dbtype prot -p ${i} -w ${i} -time 120 -h tc -d /fastscratch/karimy/SparkLogs
done

# -i --> input raw databaase path
# -t --> formatted database path
# -q --> query
# -t --> time
# The rest are BLAST parameters, you can keep as is for now
