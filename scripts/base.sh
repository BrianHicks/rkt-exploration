#!/bin/bash
set -e

# system upgrades
yum update -y
yum install -y epel-release tree jq git ack
