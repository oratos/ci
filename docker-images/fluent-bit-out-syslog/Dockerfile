FROM golang:latest as builder

COPY / /home

WORKDIR /home

RUN go version

RUN go mod download

ENV GOOS=linux \
    GOARCH=amd64

RUN go build \
    -a \
    -installsuffix fluent \
    -buildmode c-shared \
    -o /out_syslog.so \
    -mod=readonly \
    cmd/main.go

FROM fluent/fluent-bit:0.13.4

COPY --from=builder /out_syslog.so /fluent-bit/bin/

WORKDIR "/fluent-bit/etc"
CMD ["/fluent-bit/bin/fluent-bit", "--plugin", "/fluent-bit/bin/out_syslog.so", "--config", "/fluent-bit/etc/fluent-bit.conf"]
