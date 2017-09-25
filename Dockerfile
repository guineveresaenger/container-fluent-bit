FROM golang:1.9.0 as builder
MAINTAINER Leah Petersen <leahnpetersen@gmail.com>
LABEL Description="Fluent Bit Docker image" Vendor="Samsung CNCT" Version="0.1"

ENV FLB_MAJOR 0
ENV FLB_MINOR 12
ENV FLB_PATCH 2
ENV FLB_VERSION 0.12.2
ENV GOPATH /go
ENV GOBIN $GOPATH/bin
ENV PATH $GOBIN:$PATH

USER root

# Install build tools
RUN apt-get -qq update && \
    apt-get install -y -qq curl ca-certificates build-essential cmake iputils-ping dnsutils make bash sudo wget unzip libsystemd-dev nano vim valgrind golang git  && \
    apt-get install -y -qq --reinstall lsb-base lsb-release && \  
    wget -O "/tmp/fluent-bit-$FLB_VERSION-dev.zip" "https://github.com/fluent/fluent-bit/archive/v$FLB_VERSION.zip" && \
    cd /tmp && \
    unzip "fluent-bit-$FLB_VERSION-dev.zip" && \
    cd "fluent-bit-$FLB_VERSION/build/" && \
    cmake -DCMAKE_INSTALL_PREFIX=/fluent-bit/ .. && \
    make && make install && \
    cd / && \
    git clone https://github.com/samsung-cnct/fluent-bit-kafka-output-plugin && \
    cd fluent-bit-kafka-output-plugin && \
    make && \
    rm -rf /tmp/* /fluent-bit/include /fluent-bit/lib*

FROM golang:alpine as runtime

COPY fluent-bit.conf /fluent-bit/etc/
COPY parsers.conf /fluent-bit/etc/
COPY start.sh /
RUN ["chmod", "+x", "/start.sh"]

CMD ["/fluent-bit/bin/fluent-bit", "-e", "/fluent-bit-kafka-output-plugin/out_kafka.so", "-c", "/fluent-bit/etc/fluent-bit.conf"]
