FROM python:2-alpine3.11

RUN apk add --no-cache --upgrade bash go git musl-dev
RUN apk add --upgrade make
# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin
