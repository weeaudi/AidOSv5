# Dockerfile
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

ARG BINUTILS_VERSION=2.35
ARG GCC_VERSION=15.2.0
ARG NASM_VERSION=3.01

ARG TARGET=x86_64-elf
ARG PREFIX_DIR=/opt/cross
ARG JOBS=16

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl wget ca-certificates xz-utils bzip2 tar \
    git \
    python3 \
    texinfo \
    bison flex \
    gawk \
    cmake \
    parted \
    libgmp-dev libmpfr-dev libmpc-dev libisl-dev \
    file \
    && rm -rf /var/lib/apt/lists/*

ENV PREFIX=${PREFIX_DIR}
ENV TARGET=${TARGET}
ENV PATH=${PREFIX}/bin:${PATH}

WORKDIR /opt/src


RUN set -eux; \
    wget -O binutils.tar.xz "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"; \
    wget -O gcc.tar.xz      "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"; \
    wget -O nasm.tar.xz     "https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.xz" || true; \
    mkdir -p /opt/build/binutils /opt/build/gcc /opt/build/nasm; \
    tar -xf binutils.tar.xz; \
    tar -xf gcc.tar.xz; \
    if [ -f nasm.tar.xz ]; then tar -xf nasm.tar.xz; fi

RUN set -eux; \
    
      cd /opt/build/nasm; \
      "/opt/src/nasm-${NASM_VERSION}/configure"; \
      make -j${JOBS}; \
      make install;

RUN set -eux; \
    cd /opt/build/binutils; \
    "/opt/src/binutils-${BINUTILS_VERSION}/configure" \
      --target="${TARGET}" \
      --prefix="${PREFIX}" \
      --with-sysroot= \
      --disable-nls \
      --disable-werror; \
    make -j${JOBS}; \
    make install


RUN set -eux; \
    cd "/opt/src/gcc-${GCC_VERSION}"; \
    ./contrib/download_prerequisites || true

RUN set -eux; \
    cd /opt/build/gcc; \
    "/opt/src/gcc-${GCC_VERSION}/configure" \
      --target="${TARGET}" \
      --prefix="${PREFIX}" \
      --disable-nls \
      --enable-languages=c,c++ \
      --without-headers; \
    make -j6 all-gcc; \
    make -j6 all-target-libgcc; \
    make -j6 install-gcc; \
    make -j6 install-target-libgcc

RUN echo 'echo "Toolchain installed under: ${PREFIX}"; \
${TARGET}-ld --version 2>/dev/null | head -n1; \
${TARGET}-gcc --version 2>/dev/null | head -n1; \
nasm -v 2>/dev/null' > /etc/profile.d/toolchain-info.sh

run chmod +x /etc/profile.d/toolchain-info.sh

RUN echo 'export PATH=${PREFIX}/bin:$PATH' > /etc/profile.d/cross-toolchain.sh

run chmod +x /etc/profile.d/cross-toolchain.sh
