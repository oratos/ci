FROM golang:1.11 as builder

WORKDIR /root

ENV GOOS=linux \
    GOARCH=amd64 \
    CGO_ENABLED=0

COPY /go.mod /go.sum /root/

RUN go version && \
    go mod download

COPY / /root/

RUN go build \
    -a \
    -installsuffix nocgo \
    -o /latency-receiver \
    -mod=readonly \
    cmd/latency-receiver/main.go

FROM ubuntu:xenial

WORKDIR /srv

RUN apt-get update && \
    apt-get install -y openssl && \
    apt-get clean

RUN openssl genrsa -out localhost.key 2048 && \
    openssl req -new -subj '/CN=localhost' -x509 -sha256 -key localhost.key -out localhost.crt -days 3650

COPY --from=builder /latency-receiver /srv/
CMD [ "/srv/latency-receiver" ]
