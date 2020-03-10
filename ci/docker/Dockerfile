FROM alpine:latest

RUN apk update && \
    apk --no-cache add \
    ca-certificates wget bash git jq xz \
    # needed by gcloud
    python \
    # needed to render bosh templates
    ruby ruby-dev \
    # needed to run Google CPI packaging scripts
    make alpine-sdk

# both the BOSH CLI and the Google CPI Go blob are dynamically linked against glibc
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
  wget -q -O /tmp/glibc.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk && \
  apk add /tmp/glibc.apk && \
  rm -rf /tmp/glibc.apk

RUN gem install json --no-document # json is not a default gem in alpine

RUN wget -q -O /tmp/lego.tar.xz https://github.com/go-acme/lego/releases/download/v3.4.0/lego_v3.4.0_linux_amd64.tar.gz && \
  tar xf /tmp/lego.tar.xz -C /usr/local/bin/ -- lego && \
  chmod +x /usr/local/bin/lego && \
  rm /tmp/lego.tar.xz

RUN wget -O /tmp/google-sdk.tgz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-152.0.0-linux-x86_64.tar.gz && \
  tar xvf /tmp/google-sdk.tgz -C $HOME && \
  rm /tmp/google-sdk.tgz

RUN ln -s $HOME/google-cloud-sdk/bin/gcloud /usr/local/bin/
RUN ln -s $HOME/google-cloud-sdk/bin/gsutil /usr/local/bin/
