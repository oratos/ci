FROM golang:latest

RUN go version

COPY /install_packages.sh /install_packages.sh

RUN /install_packages.sh

RUN git config --global user.email "oratos-team@pivotal.io" && \
    git config --global user.name "Oratos CI"

RUN wget -q -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

RUN curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | bash -s -- -b /usr/local/bin v1.9.1
