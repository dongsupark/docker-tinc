# donsgupark/tinc

A simple docker image to run Tinc VPN. It's based on Debian unstable.

## Getting started

Build the image:

```
make
```

Run a container from the image:

```
docker run --privileged -it quay.io/dongsupark/tinc
```

Its result image will be pushed to https://quay.io/repository/dongsupark/tinc.

See also [tinc-vpn.org](https://www.tinc-vpn.org/).
