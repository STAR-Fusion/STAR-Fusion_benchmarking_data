FROM ubuntu:16.04
MAINTAINER bhaas@broadinstitute.org

RUN apt-get update && apt-get install -y gcc g++ perl python automake make \
                                       wget git curl libdb-dev zlib1g-dev bzip2 && \
				       apt-get clean

ENV SRC /usr/local/src
ENV BIN /usr/local/bin

# perl helpers

RUN curl -L https://cpanmin.us | perl - App::cpanminus

RUN cpanm install DB_File


#####
# Install R

WORKDIR $SRC

ENV R_VERSION=R-3.3.2

RUN curl https://cran.r-project.org/src/base/R-3/$R_VERSION.tar.gz -o $R_VERSION.tar.gz && \
        tar xvf $R_VERSION.tar.gz && \
        cd $R_VERSION && \
        ./configure && make && make install


RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("ggplot2", dep = TRUE)'


#######
# Install STAR-Fusion benchmark data

RUN git clone https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data.git


########
# Install Trinity (just for plotting utilities)

RUN git clone https://github.com/trinityrnaseq/trinityrnaseq.git

ENV TRINITY_HOME ${SRC}/trinityrnaseq

########
# Install benchmarking utilities

RUN git clone https://github.com/FusionSimulatorToolkit/FusionSimulatorToolkit.git

ENV FUSION_SIMULATOR ${SRC}/FusionSimulatorToolkit

#########
# Install FusionAnnotator

RUN git clone https://github.com/FusionAnnotator/FusionAnnotator.git && \
    cd FusionAnnotator && \
    make

ENV FUSION_ANNOTATOR ${SRC}/FusionAnnotator


