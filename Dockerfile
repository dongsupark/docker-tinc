FROM debian:unstable

# Tinc version
ARG TINC_VERSION=1.1pre17

ENV CONTAINER_SERVICE_DIR=/service
ENV CONTAINER_STATE_DIR=/run/state
ENV TINC_CMD_ARGS="--debug=3"

# Download, build and install Tinc
RUN apt-get -y update \
    && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apt-utils \
    awscli \
    bind9-host \
    ca-certificates \
    curl \
    gcc \
    iproute2 \
    iputils-ping \
    jq \
    less \
    libssl1.1 \
    libssl-dev \
    liblzo2-2 \
    liblzo2-dev \
    libncurses5 \
    libncurses5-dev \
    libreadline7 \
    libreadline-dev \
    make \
    nano \
    net-tools \
    openssh-server \
    pkg-config \
    procps \
    vim \
    zlib1g \
    zlib1g-dev \
    && curl -o tinc.tar.gz -SL https://www.tinc-vpn.org/packages/tinc-${TINC_VERSION}.tar.gz \
    && mkdir -p /container/tinc-sources \
    && tar -xzf tinc.tar.gz --strip 1 -C /container/tinc-sources \
    && cd /container/tinc-sources \
    && ./configure \
    && make && make install \
    && cd - \
    && mkdir -p /usr/local/var/run/ \
    && rm -f tinc.tar.gz \
    && rm -rf /container/tinc-sources

WORKDIR /root

RUN sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config
RUN update-rc.d ssh enable

RUN mkdir --parents /root/.ssh

ADD id_rsa.pub /root/.ssh/authorized_keys
ADD aws /root/.aws

ADD service /service
ADD environment /environment

RUN /service/tinc/startup.sh

EXPOSE 655/tcp 655/udp

ENTRYPOINT /usr/sbin/service ssh start && /service/tinc/process.sh
