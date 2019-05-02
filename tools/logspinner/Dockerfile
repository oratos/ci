FROM golang:1.11 as builder

WORKDIR /root

ENV GOOS=linux \
    GOARCH=amd64 \
    CGO_ENABLED=0

COPY /go.* /root/

RUN go version && \
    go mod download

COPY / /root/

RUN go build \
    -a \
    -installsuffix nocgo \
    -o /logspinner \
    -mod=readonly \
    main.go

FROM alpine:latest

COPY --from=builder /logspinner /srv/
WORKDIR /srv
EXPOSE 8080
CMD [ "/srv/logspinner" ]
