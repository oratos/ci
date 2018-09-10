FROM golang:1.11 as builder

WORKDIR /root

ENV GOOS=linux \
    GOARCH=amd64

COPY /go.mod /go.sum /root/

RUN go version && \
    go mod download

COPY / /root/

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
