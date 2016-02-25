#!/bin/bash
set -e

RKT_VERSION=1.0.0
DATA_DIR=/var/lib/rkt

# download requested version
if [ ! -d rkt-v${RKT_VERSION} ]; then
    echo downloading rkt $RKT_VERSION
    curl -L https://github.com/coreos/rkt/releases/download/v${RKT_VERSION}/rkt-v${RKT_VERSION}.tar.gz > /tmp/rkt.tar.gz
    tar -xzvf /tmp/rkt.tar.gz
    rm /tmp/rkt.tar.gz
else
    echo already have the rkt $RKT_VERSION release
fi

pushd rkt-v${RKT_VERSION}

# copy the binary
if ! echo -e $(rkt version || echo "0.0.0") | grep -q $RKT_VERSION; then
    echo installing rkt $RKT_VERSION
    cp rkt /usr/bin/rkt
else
    echo rkt $RKT_VERSION is already installed
fi

# create rkt group - must be before creating the data dir
if ! grep -q rkt /etc/group; then
    echo creating rkt group
    groupadd rkt
else
    echo rkt group already exists
fi

# add vagrant user to the rkt group
if ! groups vagrant | grep -q rkt; then
    echo adding vagrant to the rkt group
    gpasswd -a vagrant rkt
else
    echo already added vagrant to the rkt group
fi

# create rkt data dir
if [ ! -d $DATA_DIR ]; then
    echo setting up $DATA_DIR
    ./scripts/setup-data-dir.sh $DATA_DIR
else
    echo "$DATA_DIR already exists"
fi

# disable selinux
if ! grep -q permissive /etc/selinux/config; then
    echo disabling selinux
    sed -i'' 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
    setenforce Permissive # so we don't have to reboot
else
    echo selinux is already disabled
fi

# install tmpfiles.d
if [ ! -f /usr/lib/tmpfiles.d/rkt.conf ]; then
    echo installing tmpfiles conf
    cp init/systemd/tmpfiles.d/rkt.conf /usr/lib/tmpfiles.d/
else
    echo tmpfiles conf is already installed
fi

# install service files
for svc in $(find init/systemd -maxdepth 1 -type f); do
    if [ ! -f /usr/lib/systemd/system/$(basename $svc) ]; then
        echo installing $(basename $svc)
        cp $svc /usr/lib/systemd/system/$(basename $svc)
        systemctl daemon-reload
    else
        echo $(basename $svc) already installed
    fi
done

# install stage1 ACIs
if [ ! -d /usr/lib/rkt/stage1-images ]; then
    echo installing stage1 ACIs
    mkdir -p /usr/lib/rkt/stage1-images
else
    echo already created stage1 images directory
fi

for image in *.aci; do
    if [ ! -f /usr/lib/rkt/stage1-images/$image ]; then
        echo installing $image
        cp $image /usr/lib/rkt/stage1-images/
    else
        echo already installed $image
    fi
done

# symlink the images to /usr/bin because of a bug in rkt's release process. See
# https://github.com/coreos/rkt/issues/2221
for image in /usr/lib/rkt/stage1-images/*; do
    if [ ! -h /usr/bin/$(basename $image) ]; then
        echo HACK: symlinking $(basename $image) to /usr/bin
        ln -s $image /usr/bin/$(basename $image)
    else
        echo HACK: already symlinked $(basename $image) to /usr/bin
    fi
done

popd

# run a test
rkt run --trust-keys-from-https quay.io/coreos/alpine-sh --exec=/bin/echo -- "Hello, rkt!"
