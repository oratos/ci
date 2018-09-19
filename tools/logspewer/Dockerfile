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
    -o /logspewer \
    -mod=readonly \
    main.go

FROM alpine:latest

COPY --from=builder /logspewer /srv/
WORKDIR /srv
CMD [ "/srv/logspewer" ]
