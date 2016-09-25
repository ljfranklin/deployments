FROM alpine:latest

RUN apk update && \
    apk --no-cache add \
    ca-certificates wget bash git jq xz \
    # needed to render bosh templates
    ruby ruby-dev \
    # needed to run Google CPI packaging scripts
    make alpine-sdk

# both the BOSH CLI and the Google CPI Go blob are dynamically linked against glibc
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub && \
  wget -q -O /tmp/glibc.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk && \
  apk add /tmp/glibc.apk && \
  rm -rf /tmp/glibc.apk

RUN gem install json --no-rdoc --no-ri # json is not a default gem in alpine

RUN wget -q -O /tmp/lego.tar.xz https://github.com/xenolf/lego/releases/download/v0.3.1/lego_linux_amd64.tar.xz && \
  tar xf /tmp/lego.tar.xz -C /usr/local/bin/ --strip 1 -- lego/lego && \
  chmod +x /usr/local/bin/lego && \
  rm /tmp/lego.tar.xz
