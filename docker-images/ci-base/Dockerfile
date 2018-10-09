FROM golang:1.11

RUN go version

COPY /install_packages.sh /install_packages.sh

RUN /install_packages.sh

RUN git config --global user.email "oratos-team@pivotal.io" && \
    git config --global user.name "Oratos CI"

RUN wget -q -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

RUN wget -q -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/2.1.1/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

RUN curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | bash -s -- -b /usr/local/bin v1.10.2

RUN cd /tmp \
  && wget https://github.com/cloudfoundry/bosh-bootloader/releases/download/v6.6.7/bbl-v6.6.7_linux_x86-64 -O /usr/local/bin/bbl \
  && chmod +x /usr/local/bin/bbl

RUN cd /tmp \
  && wget https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/1.7.5/credhub-linux-1.7.5.tgz \
  && tar xzvf credhub*.tgz ./credhub \
  && cp ./credhub /usr/local/bin/

RUN curl -Lo ./bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-5.3.1-linux-amd64 \
  && chmod +x ./bosh \
  && sudo mv ./bosh /usr/local/bin/bosh \
  && bosh -v

RUN cd /tmp \
  && wget https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip \
  && unzip terraform*.zip \
  && cp terraform /usr/local/bin/
