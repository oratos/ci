FROM python:2-alpine3.11 AS build-env
ADD . /app
WORKDIR /app
RUN apk add --no-cache --upgrade bash



# RUN apk add --no-cache git make musl-dev go curl

# # Configure Go
# ENV GOROOT /usr/lib/go
# ENV GOPATH /go
# ENV PATH /go/bin:$PATH

# RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

# RUN curl https://gitlab.eng.vmware.com/frapposelli/osstptool/releases/



FROM kubernetes-docker-local.artifactory.eng.vmware.com/osstptool:v0.4.2
COPY --from=build-env /app /app
WORKDIR /app
