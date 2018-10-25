FROM oratos/golang-base:1.11 as builder

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
    -o /event-controller \
    -mod=readonly \
    cmd/event-controller/main.go

FROM ubuntu:bionic

COPY --from=builder /event-controller /srv/
WORKDIR /srv
CMD [ "/srv/event-controller" ]
