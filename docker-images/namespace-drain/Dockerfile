FROM golang:latest as builder

COPY / /go/

ENV GOOS=linux \
    GOARCH=amd64 \
    CGO_ENABLED=0

RUN go build \
    -a \
    -installsuffix nocgo \
    -o /namespace-drain \
    github.com/pivotal-cf/namespace-drain/cmd

FROM alpine:latest

COPY --from=builder /namespace-drain /srv/
WORKDIR /srv
CMD [ "/usr/bin/namespace-drain" ]
