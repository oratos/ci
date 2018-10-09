#!/bin/bash

apt-get update
apt-get install --yes \
        jq \
        rsync \
        unzip \
        psmisc \
        vim \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg2 \
        software-properties-common \
        netcat-openbsd \
        ruby-full

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-get install --yes docker-ce

echo "deb http://packages.cloud.google.com/apt cloud-sdk-$(lsb_release -c -s) main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update
apt-get install --yes google-cloud-sdk

rm -rf /var/lib/apt/lists/*
