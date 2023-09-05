#!/bin/bash

wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.13.0/ncbi-blast-2.13.0+-src.tar.gz -P /opt
docker buildx build  . --platform linux/arm64 --tag karimyoussef1991/sparkleblast:latest --push

