# Copyright (c) 2018-2020 NVIDIA Corporation
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Released under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.

ARG BASE_IMAGE=nvcr.io/nvidia/cuda:11.6.1-devel-ubuntu20.04

FROM ${BASE_IMAGE}

ADD libcuda.so* /usr/lib/x86_64-linux-gnu/
ADD libnvidia-ptxjitcompiler.so* /usr/lib/x86_64-linux-gnu/
