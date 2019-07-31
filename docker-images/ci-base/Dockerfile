FROM golang:1.12

RUN go version

COPY /install_packages.sh /install_packages.sh

RUN /install_packages.sh

RUN git config --global user.email "oratos-team@pivotal.io" && \
    git config --global user.name "Oratos CI"

RUN wget -q -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

RUN wget -q -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/2.1.1/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

RUN curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | bash -s -- -b /usr/local/bin v1.12.2

RUN cd /tmp \
  && wget https://github.com/cloudfoundry/bosh-bootloader/releases/download/v6.6.7/bbl-v6.6.7_linux_x86-64 -O /usr/local/bin/bbl \
  && chmod +x /usr/local/bin/bbl

ADD https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.5.2/credhub-linux-2.5.2.tgz credhub.tgz
RUN tar xzvf credhub.tgz -C /usr/local/bin ./credhub && rm credhub.tgz

RUN curl -Lo ./bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-5.3.1-linux-amd64 \
  && chmod +x ./bosh \
  && sudo mv ./bosh /usr/local/bin/bosh \
  && bosh -v

RUN cd /tmp \
  && wget https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip \
  && unzip terraform*.zip \
  && cp terraform /usr/local/bin/

RUN cd /tmp \
  && wget https://github.com/kubernetes-sigs/kustomize/releases/download/v3.0.0/kustomize_3.0.0_linux_amd64 -O /usr/local/bin/kustomize \
  && chmod +x /usr/local/bin/kustomize

ENV TELEGRAF_VERSION 1.11.0
ADD https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}-1_amd64.deb /tmp/telegraf_${TELEGRAF_VERSION}-1_amd64.deb

RUN apt install /tmp/telegraf_${TELEGRAF_VERSION}-1_amd64.deb && \
    rm /tmp/telegraf_${TELEGRAF_VERSION}-1_amd64.deb
