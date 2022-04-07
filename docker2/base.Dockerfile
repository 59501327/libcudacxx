# Copyright (c) 2018-2020 NVIDIA Corporation
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Released under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.

# SDK_TYPE needs to be a base image that contains CUDA.
# | SDK_TYPE | SDK_VER                   |
# | cuda     | 11.5.1-devel 11.6.0-devel |
# | nvhpc    | 22.1-devel-cuda11.5       |
ARG BASE_IMAGE=nvcr.io/nvidia/cuda:11.6.1-devel-ubuntu20.04
# | OS_TYPE  | OS_VER |
# | ubuntu   | 20.04  |
ARG OS_TYPE=ubuntu
ARG OS_VER=20.04

# | CXX_TYPE | CXX_VER            |
# | gcc      | 5 6 7 8 9 10 11 12 |
# | clang    | 7 8 9 10 11 12     |
# | icc      | latest             |
# | nvcxx    | 22.1               |
ARG HOST_CXX

ARG EXTRA_APT_PACKAGES

FROM ${BASE_IMAGE} AS cccl-base

ARG SDK_TYPE
ARG SDK_VER
ARG OS_TYPE
ARG OS_VER
ARG EXTRA_APT_PACKAGES
ARG HOST_CXX

# Ubuntu 20.04 doesn't have GCC 11 in its repos, so get it from the toolchain PPA.
ARG UBUNTU_TOOL_DEB_REPO=http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu
ARG UBUNTU_TOOL_FINGER=60C317803A41BA51845E371A1E9377A2BA9EF27F

# Ubuntu 20.04 doesn't have GCC 5 and GCC 6, so get it from an older release.
ARG UBUNTU_ARCHIVE_DEB_REPO="http://archive.ubuntu.com/ubuntu bionic main universe"

ARG ICC_DEB_REPO="https://apt.repos.intel.com/oneapi all main"
ARG ICC_KEY=https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB

# CentOS 7 doesn't have a new enough version of CMake in its repos.
ARG CMAKE_VER=3.22.1
ARG CMAKE_URL=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-Linux-x86_64.sh

# `--silent --show-error` disables non-error output.
# `--fail` causes `curl` to return an error code on HTTP errors.
ARG CURL="curl --silent --show-error --fail"

# `-y` answers yes to any interactive prompts.
# `--no-install-recommends` avoids unnecessary packages, keeping the image smaller.
ARG APT_GET="apt-get -y --no-install-recommends"

ENV TZ=US/Pacific
ENV DEBIAN_FRONTEND=noninteractive
# apt-key complains about non-interactive usage.
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

SHELL ["/usr/bin/env", "bash", "-c"]

# Only copy necessary CUDA bits into image
COPY . /cuda

# Install baseline development tools
ADD ${CMAKE_URL} /tmp/cmake.sh

RUN function comment() { :; }; \
    comment "Sources for gcc/clang/icc"; \
    echo "deb ${UBUNTU_ARCHIVE_DEB_REPO}" >> /etc/apt/sources.list.d/ubuntu-archive.list; \
    source /etc/os-release; \
    echo "deb ${UBUNTU_TOOL_DEB_REPO} ${UBUNTU_CODENAME} main" >> /etc/apt/sources.list; \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ${UBUNTU_TOOL_FINGER} 2>&1; \
    echo "deb ${ICC_DEB_REPO}" > /etc/apt/sources.list.d/icc.list; \
    ${CURL} -L ${ICC_KEY} -o - | apt-key add -; \
    ${APT_GET} update; \
    comment "Install basic build tools"; \
    ${APT_GET} install python3-pip python3-setuptools python3-wheel; \
    ${ALTERNATIVES} --install /usr/bin/python python $(which python3) 3; \
    ${ALTERNATIVES} --set python $(which python3); \
    ${APT_GET} install git zip unzip tar sudo openssh-client make ninja-build ccache pkg-config \
        ${EXTRA_APT_PACKAGES}; \
    sh /tmp/cmake.sh --skip-license --prefix=/usr; \
    pip install lit;

# ONBUILD specialization steps
ONBUILD ARG HOST_CXX
ONBUILD ARG APT_GET="apt-get -y --no-install-recommends"
ONBUILD RUN ${APT_GET} install ${HOST_CXX}

# Path to nvcc/nvc++ within build context
# e.g. bin/x86_release_linux/nvcc
# Applications using this parent will fail to build *quickly* if cuda/blah/executable --version fails.
# This is a feature
ONBUILD ARG CUDACXX_PATH
ONBUILD RUN /cuda/${CUDACXX_PATH} --version

CMD [ "/bin/bash" ]