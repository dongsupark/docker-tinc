FROM debian:unstable

# Tinc version
ARG TINC_VERSION=1.1pre17

# Download, build and install Tinc
RUN apt-get -y update \
    && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gcc \
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
    && rm -rf /container/tinc-sources \
    && apt-get remove -y --purge --auto-remove ca-certificates curl gcc  \
    libssl-dev liblzo2-dev libncurses5-dev libreadline-dev make pkg-config zlib1g-dev


ADD service /service
ADD environment /environment

RUN /service/tinc/startup.sh

EXPOSE 655/tcp 655/udp

ENTRYPOINT /service/tinc/process.sh
