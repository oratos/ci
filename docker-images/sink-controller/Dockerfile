FROM golang:1.11 as builder

COPY / /home

WORKDIR /home

RUN go version

RUN go mod download

ENV GOOS=linux \
    GOARCH=amd64 \
    CGO_ENABLED=0

RUN go build \
    -a \
    -installsuffix nocgo \
    -o /sink-controller \
    -mod=readonly \
    cmd/main.go

FROM alpine:latest

COPY --from=builder /sink-controller /srv/
WORKDIR /srv
CMD [ "/srv/sink-controller" ]
