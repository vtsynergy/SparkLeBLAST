#!/usr/bin/bash
mpiexec gatherhosts_ips hosts  
mpiexec ./start_spark_cluster.sh &
singularity exec --bind hosts:/etc/hosts sparkleblast_latest.sif /opt/spark-2.2.0-bin-hadoop2.6/bin/spark-shell --master spark://$(hostname):7077
