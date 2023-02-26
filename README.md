# SparkLeBLAST
Scalable Parallelization of BLAST Sequence Alignment Using Spark

## Dependencies
### Spark
We conducted our experiments using Spark v2.2.0. (https://archive.apache.org/dist/spark/spark-2.2.0/)

### NCBI BLAST
SparkLeBLAST works independent of a specific BLAST version. We recently tested it with BLAST v2.13.0: 
(https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)

### spark-slurm
For usage on an HPC cluster with SLURM workload manager (details below), there are two approaches:
1) Use the shipped start_spark_slurm.sbatch script
2) USe spark-slurm (https://github.com/NIH-HPC/spark-slurm)
   Note: spark-slurm enables more flexible configurations and logging options. It may need some edits to adapt it to your runtime environment.
   Our adapted version is available at: (https://github.com/karimyoussef91/spark-slurm)

## Usage
### HPC Cluster With SLURM Workload Manager
1) Partitioning and formatting a BLAST database:

   a)  
```shell script 
     export NCBI_BLAST_PATH=</path/to/ncbi_blast/binaries>
```
   b) 
```shell script
    ./SparkLeMakeDB -p <num_partitions> -time <job_time_integer_minutes> -i <input_DB_path> -t <output_partitions_base_path>
``` 
2) Running BLAST search:
```shell script
   ./SparkLeBLASTSearch.sh -p <num_partitions> -time <job_time_integer_minutes> -q <query_file_path> -db <database_partitions_base_path> -d <spark_logs_path>
```

### Custom Spark Cluster
A version of launch scripts without SLURM will be available soon

## Publication
Youssef, Karim, and Wu-chun Feng. "SparkLeBLAST: Scalable Parallelization of BLAST Sequence Alignment Using Spark." 2020 20th IEEE/ACM International Symposium on Cluster, Cloud and Internet Computing (CCGRID). IEEE, 2020.

## License
Please refer to the included LICENSE file.
