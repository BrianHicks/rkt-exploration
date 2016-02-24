#!/bin/bash
set -e

CALICO_CNI_VERSION=1.0.2

# download calicoctl
if ! which calicoctl; then
    echo downloading calicoctl
    curl -L https://www.projectcalico.org/builds/calicoctl > /usr/bin/calicoctl
    chmod +x /usr/bin/calicoctl
else
    echo already downloaded calicoctl
fi

# make /etc/rkt/net.d
if [ ! -d /etc/rkt/net.d ]; then
    echo making rkt net.d
    mkdir -p /etc/rkt/net.d
    chmod a+w -R /etc/rkt/net.d
else
    echo rkt net.d exists
fi

# download calico CNI
if [ ! -f /etc/rkt/net.d/calico ]; then
    echo downloading calico CNI ${CALICO_CNI_VERSION}
    curl -L https://github.com/projectcalico/calico-cni/releases/download/v${CALICO_CNI_VERSION}/calico > /etc/rkt/net.d/calico
    chmod +x /etc/rkt/net.d/calico
else
    echo already downloaded calico CNI ${CALICO_CNI_VERSION}
fi

# download docker images
for image in busybox calico/node; do
    if ! rkt image list | grep -q $image; then
        echo fetching $image
        rkt --insecure-options=image fetch docker://$image
    else
        echo already fetched $image
    fi
done

# symlink the stage1 ACIs to /usr/share/rkt, since Calico doesn't seem
# configurable where it looks for these
[[ ! -d /usr/share/rkt ]] && mkdir -p /usr/share/rkt

for image in /usr/lib/rkt/stage1-images/*; do
    if [ ! -h /usr/share/rkt/$(basename $image) ]; then
        echo symlinking $(basename $image) to /usr/share/rkt
        ln -s $image /usr/share/rkt/$(basename $image)
    else
        echo already symlinked $(basename $image) to /usr/bin
    fi
done

# run calico node
if ! systemctl status calico-node | grep -q running; then
    if systemctl status calico-node | grep -q not-found; then
        echo running calico-node initially
        calicoctl node --runtime=rkt
    else
        echo running calico-node
        systemctl start calico-node
    fi
else
    echo calico-node already running
fi

# create calico networks
echo installing calico network
cat > /etc/rkt/net.d/10-calico-default.conf <<EOF
{
    "name": "calico-default",
    "type": "calico",
    "ipam": {
        "type": "calico-ipam"
    }
}
EOF
