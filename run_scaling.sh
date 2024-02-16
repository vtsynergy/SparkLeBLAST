#!/bin/bash

# 128 nodes, preemptable_q
export SPARK_SLURM_PATH=/projects/synergy_lab/ritvik/Voltron/Dependencies/spark-slurm/spark_normal_full_node_nohadoop
export SPARK_HOME=/projects/synergy_lab/ritvik/Voltron/Dependencies/spark-2.2.0-bin-hadoop2.6 # Where pre-built Spark was downloaded from dependencies abpve 
# export NCBI_BLAST_PATH=/home/karimy/ncbi-blast-2.13.0+-src/c++/ReleaseMT/bin
export SLB_WORKDIR=/projects/synergy_lab/ritvik/Voltron/SparkLeBLAST # Path to SparkLeBLAST root directory
export SPARK_LOCAL_DIRECTORY=/home/ritvikp/tmpSpark
export COMPILED_SCALA_DIRECTORY=target/scala-2.11/simple-project_2.11-1.0.jar

#spark_slurm
export SPARKLOGS_DIR=/fastscratch/ritvikp/SparkLogs


# ./SparkLeMakeAndSearch.sh -i /fastscratch/karimy/blastDB/nr -t /fastscratch/karimy/blastDB/nr_formatted -q /fastscratch/karimy/blastDB/GeobacterMetallireducens.fasta -o T  -dbtype prot -p 128 -w 128 -time 480 -h tc -d /fastscratch/karimy/SparkLogs

# Other configs, normal_q
# export SPARK_SLURM_PATH=/home/karimy/spark-slurm/spark

for i in 4; do
./SparkLeMakeAndSearch.sh -i /fastscratch/karimy/blastDB/uniprot_sprot.fasta -t /localscratch/uniprot_sprot_formatted -q /fastscratch/karimy/blastDB/geobacter_8_partitions/GeobacterMetallireducens_8.fasta -o T  -dbtype prot -p ${i} -w ${i} -time 120 -h tc -d ${SPARKLOGS_DIR}
done

# -i --> input raw databaase path
# -t --> formatted database path
# -q --> query
# -t --> time
# The rest are BLAST parameters, you can keep as is for now
