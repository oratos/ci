FROM golang:latest as builder

COPY / /go/

ENV GOOS=linux \
    GOARCH=amd64

RUN go build \
    -o /controller \
    github.com/pivotal-cf/namespace-drain/cmd/

FROM alpine:latest

COPY --from=builder /controller /usr/bin/

CMD ["/usr/bin/controller"]
