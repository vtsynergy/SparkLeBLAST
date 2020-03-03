#!/bin/bash

# SBATCH --time=03:00:00
# SBATCH --nodes=1
# SBATCH --ntasks=1
# SBATCH -A hpcbigdata2
# SBTACH -p normal_q

module load jdk

masterAddress="spark://ca015.ca.arc.internal:7077"
dbPath="/work/cascades/karimy/blastDB/nr"
numPartitions=1000
dbName="/work/cascades/karimy/blastDB/nr_1000_indexed"
/home/karimy/spark-2.2.0-bin-hadoop2.6/bin/spark-submit --conf "spark.local.dir=/home/karimy/tmpSpark" --conf "spark.network.timeout=3600" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=120g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=100g" --master $masterAddress --driver-memory 100g --executor-memory 100g --class MakeDB target/scala-2.11/simple-project_2.11-1.0.jar $numPartitions $dbPath "/home/karimy/SparkLeBLAST/formatdbScript" $dbName;
