FROM golang:latest as builder

COPY / /go/

ENV GOOS=linux \
    GOARCH=amd64 \
    CGO_ENABLED=0

RUN go version

RUN go build \
    -a \
    -installsuffix nocgo \
    -o /syslog-receiver \
    tools/syslog-receiver

FROM alpine:latest

COPY --from=builder /syslog-receiver /srv/
WORKDIR /srv
CMD [ "/srv/syslog-receiver" ]
