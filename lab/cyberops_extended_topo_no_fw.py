#!/usr/bin/python3
from mininet.net import Mininet
from mininet.node import Node
from mininet.cli import CLI
from mininet.log import setLogLevel

class LinuxRouter(Node):
    def config(self, **params):
        super().config(**params)
        self.cmd('sysctl -w net.ipv4.ip_forward=1')

    def terminate(self):
        self.cmd('sysctl -w net.ipv4.ip_forward=0')
        super().terminate()

def run():
    net = Mininet()

    r1 = net.addHost('R1', cls=LinuxRouter, ip='209.165.200.1/24')
    h5 = net.addHost('H5', ip='209.165.200.235/24', defaultRoute='via 209.165.200.1')
    h10 = net.addHost('H10', ip='209.165.202.133/24', defaultRoute='via 209.165.202.1')

    net.addLink(h5, r1)
    net.addLink(r1, h10)

    net.start()
    CLI(net)
    net.stop()

if __name__ == '__main__':
    setLogLevel('info')
    run()
