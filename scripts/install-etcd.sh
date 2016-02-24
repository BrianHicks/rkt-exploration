#!/bin/bash
set -e

ETCD_VERSION=2.2.5
ETCD_IMAGE=coreos.com/etcd:v${ETCD_VERSION}

# download etcd image
if ! rkt image list | grep ${ETCD_IMAGE}; then
    echo downloading etcd $ETCD_VERSION
    rkt fetch --trust-keys-from-https ${ETCD_IMAGE}
else
    echo already downloaded etcd $ETCD_VERSION
fi

# install systemd service
cat > /tmp/etcd.service <<EOF
[Unit]
Description=etcd

[Service]
ExecStartPre=/usr/bin/rkt fetch ${ETCD_IMAGE}
Environment=HOST_IP=$(cat /etc/meta/private_ip)
Environment=HOSTNAME=$(cat /etc/meta/hostname)
ExecStart=/usr/bin/rkt run --mds-register=false --net=host \\
                           ${ETCD_IMAGE} -- --name \${HOSTNAME} \\
                                            --advertise-client-urls http://\${HOST_IP}:2379,http://\${HOST_IP}:4001 \\
                                            --listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \\
                                            --listen-peer-urls http://0.0.0.0:2380
KillMode=mixed
Restart=always

[Install]
WantedBy=multi-user.target
EOF

if ! diff /tmp/etcd.service /usr/lib/systemd/system/etcd.service; then
    echo installing etcd $ETCD_VERSION service
    mv /tmp/etcd.service /usr/lib/systemd/system/etcd.service
    systemctl daemon-reload
    systemctl enable etcd.service
    systemctl start etcd.service
else
    echo etcd $ETCD_VERSION already installed
    rm /tmp/etcd.service
fi
