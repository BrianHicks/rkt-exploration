#!/bin/bash
set -e

ACBUILD_VERSION=0.2.2

# download requested version
if ! echo -e $(acbuild version || echo "0.0.0") | grep -q $ACBUILD_VERSION; then
    echo downloading acbuild $ACBUILD_VERSION
    curl -L https://github.com/appc/acbuild/releases/download/v${ACBUILD_VERSION}/acbuild.tar.gz > /tmp/acbuild.tar.gz
    tar -xzvf /tmp/acbuild.tar.gz -C /usr/bin
    rm /tmp/acbuild.tar.gz
else
    echo already have acbuild $ACBUILD_VERSION
fi
