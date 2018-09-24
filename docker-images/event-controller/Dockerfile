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
    -o /events-controller \
    -mod=readonly \
    cmd/events-controller/main.go

FROM alpine:latest

COPY --from=builder /events-controller /srv/
WORKDIR /srv
CMD [ "/srv/events-controller" ]
