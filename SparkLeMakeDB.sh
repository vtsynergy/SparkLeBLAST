#!/bin/bash

#SBATCH --time=07:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -A <allocation_name>
#SBTACH -p <partition_name>

module load jdk

masterAddress="spark://<HOSTNAME>:7077"
dbPath="/path/to/db"
numPartitions=1000
dbName="$dbPath_<name>"
<path_to_spark_bin>/spark-submit --conf "spark.local.dir=/home/karimy/tmpSpark" --conf "spark.network.timeout=3600" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=124g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=124g" --master $masterAddress --driver-memory 124g --executor-memory 124g --class MakeDB target/scala-2.11/simple-project_2.11-1.0.jar $numPartitions $dbPath "<SparkLeBLAST_base_dir>/formatdbScript" $dbName;
