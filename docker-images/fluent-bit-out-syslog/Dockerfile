FROM golang:latest as builder

COPY / /go/

ENV GOOS=linux \
    GOARCH=amd64

RUN go build \
    -a \
    -installsuffix fluent \
    -buildmode c-shared \
    -o /out_syslog.so \
    github.com/oratos/out_syslog/cmd

FROM fluent/fluent-bit:0.13.4

COPY --from=builder /out_syslog.so /fluent-bit/bin/

CMD [ "/fluent-bit/bin/fluent-bit", "--plugin", "/fluent-bit/bin/out_syslog.so" "--config", "/fluent-bit/etc/fluent-bit.conf" ]
