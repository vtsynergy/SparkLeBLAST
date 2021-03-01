#!/bin/bash

#SBATCH --time=07:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -A hpcbigdata2
#SBTACH -p normal_q

module load jdk

masterAddress="spark://dt003.dt.arc.internal:7077"
dbPath="/work/dragonstooth/karimy/blastDB/swissprot.fasta"
numPartitions=48
dbName="/work/dragonstooth/karimy/blastDB/swissprot_48_indexed"
/home/karimy/spark-2.2.0-bin-hadoop2.6/bin/spark-submit --conf "spark.local.dir=/home/karimy/tmpSpark" --conf "spark.network.timeout=3600" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=124g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=124g" --master $masterAddress --driver-memory 124g --executor-memory 124g --class SparkLeMakeDB target/scala-2.11/simple-project_2.11-1.0.jar $numPartitions $dbPath "/home/karimy/SparkLeBLAST/formatdbScript" $dbName;
