# Running SparkLeBLAST Using Singularity 

## Requirements
1) Singularity Container Platform
2) Allocated compute nodes using any job scheduler
3) Any version of MPI (used only to setup the Spark cluster on allocated nodes)

## Pull container image and create logging directories
```shell script
    ./init.sh # This will create 3 directories (log, work, and run)
```

## Allocate Resources
Use a job scheduler (e.g., SLURM) to allocate a group of nodes. 

## Start a Spark Cluster
```shell script
    mpirun -np <num_nodes> ./start_spark_cluster.sh & # The ampersand is important to throw this to the background
```

## Verify the Spark Cluster is Working
```shell script
    singularity exec --bind hosts:/etc/hosts sparkleblast_latest.sif /opt/spark-2.2.0-bin-hadoop2.6/bin/spark-shell --master spark://<master_hostname>:7077
```
The above command should drop a Spark shell and print the master address as provide above

## Stop Spark Cluster
```shell script
    mpirun -np <num_nodes> ./stop_spark_cluster.sh                   
```

## Download Test Query and Database:
coming soon...
### Query file
### Database

## Make a BLAST Database

## Run a BLAST Search

## Run the COVID-19 Taxonomic Assignment BLAST Step:
Coming soon...
