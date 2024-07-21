# Copyright (c) 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Authors:
# - Philippe Sauter <phsauter@ethz.ch>
#
# based on: https://docs.docker.com/build/building/multi-stage/
# syntax=docker/dockerfile:1
ARG DOCKER_BASE_IMG=almalinux:8.9
ARG PICKLE_IMG
ARG YOSYS_IMG
ARG OPENROAD_IMG
FROM ${PICKLE_IMG} as pickle
FROM ${YOSYS_IMG} as yosys
FROM ${OPENROAD_IMG} as openroad

FROM ${DOCKER_BASE_IMG} AS runner
# install packages
COPY packages.txt /packages.txt
RUN yum update -y && yum install -y $(cat /packages.txt)
COPY requirements.txt /requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# copy into runnner
COPY --from=pickle /build /build
COPY --from=yosys /build /build
COPY --from=openroad /build /build

# gui
RUN dbus-uuidgen --ensure

# install texinfo
RUN mkdir texinfo && \
    cd texinfo && \
    curl -L https://ftp.gnu.org/gnu/texinfo/texinfo-7.1.tar.gz | tar -xzC . --strip-components=1 && \
    ./configure --prefix=/usr && \
    make && \
    make check && \
    make install

# Install risc-v toolchain
RUN git clone https://github.com/riscv/riscv-gnu-toolchain.git --recurse-submodules
RUN cd /riscv-gnu-toolchain && git checkout 1358115 && git submodule update
RUN cd /riscv-gnu-toolchain && ./configure --prefix=/opt/riscv
RUN cd /riscv-gnu-toolchain && make 

ENV PATH /build/bin:/opt/riscv/bin:$PATH
ENV LD_LIBRARY_PATH=/build/lib:$LD_LIBRARY_PATH
CMD /bin/bash
