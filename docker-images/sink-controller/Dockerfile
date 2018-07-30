FROM golang:latest as builder

COPY / /go/

ENV GOOS=linux \
    GOARCH=amd64 \
    CGO_ENABLED=0

RUN go build \
    -a \
    -installsuffix nocgo \
    -o /sink-controller \
    github.com/pivotal-cf/namespace-drain/cmd

FROM alpine:latest

COPY --from=builder /sink-controller /srv/
WORKDIR /srv
CMD [ "/srv/sink-controller" ]
