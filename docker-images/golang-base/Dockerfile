FROM ubuntu:bionic

WORKDIR /root

COPY /install_packages.sh /install_packages.sh

RUN /install_packages.sh

ADD https://dl.google.com/go/go1.11.linux-amd64.tar.gz go1.11.tar.gz

RUN tar -xvf go1.11.tar.gz && \
    mv go /usr/local

ENV GOPATH /root/go
RUN mkdir -p $GOPATH

ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
