FROM ubuntu:22.10

RUN apt upgrade && apt update && apt install -y wget && apt install -y curl && apt install -y openjdk-8-jdk && apt install -y ant && \
    apt install -y scala && apt install -y dropbear && apt install -y openssh-client && apt install -y openssh-server && \
    wget https://archive.apache.org/dist/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.6.tgz -P /opt && \
    tar -xvf /opt/spark-2.2.0-bin-hadoop2.6.tgz -C /opt && \
    wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.13.0+-x64-linux.tar.gz -P /opt && \
    tar -xvf /opt/ncbi-blast-2.13.0+-x64-linux.tar.gz -C /opt && \
    wget https://github.com/sbt/sbt/releases/download/v1.8.2/sbt-1.8.2.tgz -P /opt && \
    tar -xvf /opt/sbt-1.8.2.tgz -C /opt && \
    curl -L https://github.com/vtsynergy/SparkLeBLAST/tarball/master -o /opt/sparkleblast.tgz && \
    tar -xvf /opt/sparkleblast.tgz -C /opt && mv /opt/vtsynergy-* /opt/sparkleblast && \
    cd /opt/sparkleblast && /opt/sbt/bin/sbt package && cd / && useradd -ms /bin/bash slb && \
    echo "export SPARK_HOME=/opt/spark-2.2.0-bin-hadoop2.6" >> /home/slb/.bashrc && \
    echo "export NCBI_BLAST_PATH=/opt//opt/ncbi-blast-2.13.0+" >> /home/slb/.bashrc && \
    echo "export SLB_WORKDIR=/opt/sparkleblast"

USER slb
WORKDIR /home/slb

CMD ["/bin/bash"]
