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

FROM ubuntu:latest

RUN groupadd --system logspewer --gid 1000 && \
    useradd --no-log-init --system --gid logspewer logspewer --uid 1000

USER 1000:1000

COPY --from=builder /logspewer /srv/
WORKDIR /srv
CMD [ "/srv/logspewer" ]
