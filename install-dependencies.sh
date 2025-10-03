#!/bin/bash

set -eux

sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo
yum install -y curl tar bzip2 gzip xz make git file gcc gcc-c++ m4
