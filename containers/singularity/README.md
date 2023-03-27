# Running SparkLeBLAST Using Singularity 

## Requirements
1) Singularity Container Platform
2) Allocated compute nodes using any job scheduler
3) Any version of MPI (used only to setup the Spark cluster on allocated nodes)

## Pull container image and create logging directories
```shell script
    ./init.sh
```

## Allocate Resources
Use a job scheduler (e.g., SLURM) to allocate a group of nodes. 

## Start a Spark Cluster
Select a node from the allocated nodes in previous step to be the master node. 
Provide the master node hostname to the script below
```shell script
    ./start_spark_cluster.sh <master_node_hostname> <number_of_workers>
```

## Download Test Query and Database
### Query file
### Database

## Make a BLAST Database

## Run a BLAST Search

## Run the COVID-19 Taxonomic Assignment BLAST Step:
Coming soon...
