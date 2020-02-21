FROM python:2-alpine3.11

RUN apk add --no-cache git make musl-dev go

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

RUN go get -u https://gitlab.eng.vmware.com/frapposelli/osstptool
RUN cd osstptool \
  && make \
  && sudo cp /usr/local/bin
