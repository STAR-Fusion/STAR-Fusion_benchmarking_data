FROM ubuntu:16.04
MAINTAINER bhaas@broadinstitute.org

RUN apt-get update && apt-get install -y gcc g++ perl python wget git curl




ENV SRC /usr/local/src
ENV BIN /usr/local/bin


#####
# Install R

WORKDIR $SRC

ENV R_VERSION=R-3.3.2

RUN curl https://cran.r-project.org/src/base/R-3/$R_VERSION.tar.gz -o $R_VERSION.tar.gz && \
        tar xvf $R_VERSION.tar.gz && \
        cd $R_VERSION && \
        ./configure && make && make install


RUN Rscript -e 'source("http://bioconductor.org/biocLite.R");library(BiocInstaller); biocLite("ggplot2", dep = TRUE)'

