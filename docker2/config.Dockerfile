# Copyright (c) 2018-2020 NVIDIA Corporation
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Released under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.

# | CXX_TYPE | CXX_VER            |
# | gcc      | 5 6 7 8 9 10 11 12 |
# | clang    | 7 8 9 10 11 12     |
# | icc      | latest             |
# | nvcxx    | 22.1               |
ARG HOST_CXX=gcc
ARG CXX_DIALECT=17

# Default path corresponding to CTK convention, overridable for QA
ARG CUDACXX_PATH=bin/nvcc

# Assemble libcudacxx specific bits
FROM cccl/base AS libcudacxx-configured

ARG HOST_CXX
ARG CXX_DIALECT
# Attempt to load env from cccl/cuda
ARG CUDACXX_PATH

ADD . /libcudacxx

# Install compiler and configure project
RUN function comment() { :; }; \
    cmake -S /libcudacxx -B /build \
        -DLIBCUDACXX_ENABLE_STATIC_LIBRARY=OFF \
        -DLIBCUDACXX_ENABLE_LIBCUDACXX_TESTS=ON \
        -DLIBCUDACXX_ENABLE_LIBCXX_TESTS=ON \
        -DLIBCUDACXX_TEST_STANDARD_VER=c++${CXX_DIALECT} \
        -DCMAKE_CXX_COMPILER=${HOST_CXX} \
        -DCMAKE_CUDA_COMPILER=/cuda/${CUDACXX_PATH} && \
    make -j -C /build/libcxx
