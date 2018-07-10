FROM golang:latest as builder

COPY / /go/

ENV GOOS=linux \
    GOARCH=amd64

RUN go build \
    -o /namespace-drain \
    github.com/pivotal-cf/namespace-drain/cmd/

FROM alpine:latest

COPY --from=builder /namespace-drain /usr/bin/

CMD ["/usr/bin/namespace-drain"]
