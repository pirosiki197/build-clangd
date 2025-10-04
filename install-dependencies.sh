#!/bin/bash

set -eux

#sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
#sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo
yum install -y curl tar bzip2 gzip xz make git file gcc gcc-c++ m4 flex python3 python3-devel
curl -sSL https://github.com/Kitware/CMake/releases/download/v4.1.2/cmake-4.1.2-linux-x86_64.tar.gz | tar -xz -C /usr/local --strip-components=1
