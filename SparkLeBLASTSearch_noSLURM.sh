#!/bin/bash

module load jdk

masterAddress="spark://ca015.ca.arc.internal:7077"
# queryPath="/home/karimy/SparkSequenceDataSampler/query_1000_1.fasta/part-00000"
queryPath="/home/karimy/SparkBLAST/bacteria/Galaxy25-[Geobacter_metallireducens.fasta].fasta"
dbPath="/work/cascades/karimy/blastDB/nr_1000_indexed"
partitionsIDs="_partitionsIDs"
dbLen=$(head -n 1 "$dbPath/database.dbs")
numSeq=$(tail -n 1 "$dbPath/database.dbs")
gapOpen=10
gapExtend=1
outputFormat=8
rm -rf /home/karimy/SparkLeBLAST/finalOutput*
time /home/karimy/spark-2.2.0-bin-hadoop2.6/bin/spark-submit --conf "spark.network.timeout=1200" --conf "spark.eventLog.enabled=true" --conf "spark.eventLog.dir=/home/karimy/SparkLeBLAST/" --conf "spark.driver.extraJavaOptions=-XX:MaxHeapSize=124g" --conf "spark.worker.extraJavaOptions=-XX:MaxHeapSize=124g" --conf "spark.local.dir=/home/karimy/spark/tmp" --conf "spark.executor.extraJavaOptions=-Djava.io.tmpdir=/home/karimy/spark/tmp" --conf "spark.driver.extraJavaOptions=-Djava.io.tmpdir=/home/karimy/spark/tmp"  --master $masterAddress --driver-memory 124g --executor-memory 124g --class BlastSearch target/scala-2.11/simple-project_2.11-1.0.jar "$dbPath$partitionsIDs" $queryPath $dbPath "/home/karimy/SparkLeBLAST/blastSearchScript" $dbLen $numSeq $gapOpen $gapExtend $outputFormat; # hadoop dfs -getmerge output output.local
