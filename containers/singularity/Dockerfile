# Author emil.vatai@riken.jp,karimy@vt.edu
# Version v0.1.0
#
# Dockerfile for sparkleblast-base docker image.
#
# Build command (example): 
#
#   docker buildx build  . --platform linux/arm64 --tag karimyoussef1991/sparkleblast-base:latest --push
#
# To build arm64 on x86_64 you might need:
#
#   docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
#
FROM ubuntu:22.04

RUN apt-get upgrade
RUN apt-get update
RUN apt-get install -y wget curl openjdk-8-jdk ant build-essential scala dropbear openssh-client openssh-server

RUN wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.13.0/ncbi-blast-2.13.0+-src.tar.gz -P /opt
RUN tar -xvf /opt/ncbi-blast-2.13.0+-src.tar.gz -C /opt
WORKDIR /opt/ncbi-blast-2.13.0+-src/c++
RUN ./configure
RUN make -j

RUN wget https://archive.apache.org/dist/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.6.tgz -P /opt
RUN tar -xvf /opt/spark-2.2.0-bin-hadoop2.6.tgz -C /opt
RUN wget https://github.com/sbt/sbt/releases/download/v1.8.2/sbt-1.8.2.tgz -P /opt
RUN tar -xvf /opt/sbt-1.8.2.tgz -C /opt

USER slb
WORKDIR /home/slb

CMD ["/bin/bash"]
