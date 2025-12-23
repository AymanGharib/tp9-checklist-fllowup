FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo python3 python3-pip \
    mininet openvswitch-switch iproute2 iputils-ping net-tools tcpdump wget curl \
    snort \
    xterm \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY lab/ /lab/
WORKDIR /lab
CMD ["/bin/bash"]
