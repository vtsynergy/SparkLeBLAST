FROM ubuntu:22.10

RUN apt upgrade && apt update && apt install -y wget && apt install -y curl && apt install -y openjdk-8-jdk && apt install -y ant
RUN apt install -y gcc
RUN apt install -y g++
RUN apt install -y make
RUN wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.13.0/ncbi-blast-2.13.0+-src.tar.gz -P /opt
RUN tar -xvf /opt/ncbi-blast-2.13.0+-src.tar.gz -C /opt && \
    cd /opt/ncbi-blast-2.13.0+-src/c++ && \
    ./configure && \
    make && \
    cd
RUN apt install -y scala && apt install -y dropbear && apt install -y openssh-client && apt install -y openssh-server
RUN wget https://archive.apache.org/dist/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.6.tgz -P /opt
RUN tar -xvf /opt/spark-2.2.0-bin-hadoop2.6.tgz -C /opt
RUN wget https://github.com/sbt/sbt/releases/download/v1.8.2/sbt-1.8.2.tgz -P /opt
RUN tar -xvf /opt/sbt-1.8.2.tgz -C /opt
RUN curl -L https://github.com/vtsynergy/SparkLeBLAST/tarball/master -o /opt/sparkleblast.tgz && \
    tar -xvf /opt/sparkleblast.tgz -C /opt && mv /opt/vtsynergy-* /opt/sparkleblast && \
    cd /opt/sparkleblast && /opt/sbt/bin/sbt package && cd / && useradd -ms /bin/bash slb && \
    echo "export SPARK_HOME=/opt/spark-2.2.0-bin-hadoop2.6" >> /home/slb/.bashrc && \
    echo "export NCBI_BLAST_PATH=/opt/ncbi-blast-2.13.0+/c++/ReleaseMT" >> /home/slb/.bashrc && \
    echo "export SLB_WORKDIR=/opt/sparkleblast" >> /home/slb/.bashrc

USER slb
WORKDIR /home/slb

CMD ["/bin/bash"]
