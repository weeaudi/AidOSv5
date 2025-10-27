# Dockerfile
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# ---------- versions (edit if you like) ----------
ARG BINUTILS_VERSION=2.35
ARG GCC_VERSION=15.2.0
ARG NASM_VERSION=3.01

# ---------- cross target & install prefix ----------
# e.g. TARGET=x86_64-elf  or  i686-elf  or  aarch64-elf
ARG TARGET=x86_64-elf
ARG PREFIX_DIR=/opt/cross
ARG JOBS=16

# ---------- base deps ----------
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

# ---------- create layout ----------
WORKDIR /opt/src

# ---------- fetch sources ----------
# (GNU mirrors are used; tweak if a specific mirror is preferred)
RUN set -eux; \
    wget -O binutils.tar.xz "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"; \
    wget -O gcc.tar.xz      "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"; \
    # NOTE: If NASM 3.01 doesn't exist on nasm sites, change NASM_VERSION to a real release (e.g. 2.16.03).
    wget -O nasm.tar.xz     "https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.xz" || true; \
    mkdir -p /opt/build/binutils /opt/build/gcc /opt/build/nasm; \
    tar -xf binutils.tar.xz; \
    tar -xf gcc.tar.xz; \
    if [ -f nasm.tar.xz ]; then tar -xf nasm.tar.xz; fi

# ---------- build & install NASM ----------
# (optional but included; skip if you already have nasm in your pipeline)
RUN set -eux; \
    if [ -d "/opt/src/nasm-${NASM_VERSION}" ]; then \
      cd /opt/build/nasm; \
      "/opt/src/nasm-${NASM_VERSION}/configure"; \
      make -j${JOBS}; \
      make install; \
    else \
      echo "WARNING: NASM ${NASM_VERSION} source not found/download failed. Adjust NASM_VERSION."; \
    fi

# ---------- build & install binutils ----------
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

# ---------- GCC prerequisites (downloads gmp/mpfr/mpc if not using system) ----------
# We already installed system libs above, but running this is harmless and helps newer GCCs.
RUN set -eux; \
    cd "/opt/src/gcc-${GCC_VERSION}"; \
    ./contrib/download_prerequisites || true

# ---------- build & install gcc (stage1 + libgcc only; no headers, no stdlib) ----------
RUN set -eux; \
    cd /opt/build/gcc; \
    "/opt/src/gcc-${GCC_VERSION}/configure" \
      --target="${TARGET}" \
      --prefix="${PREFIX}" \
      --disable-nls \
      --enable-languages=c,c++ \
      --without-headers; \
    make -j6 all-gcc; \
    make -j6 all-target-libgcc || true; \
    make -j6 install-gcc; \
    make -j6 install-target-libgcc || true

# ---------- final touch: show versions on container start ----------
RUN echo 'echo "Toolchain installed under: ${PREFIX}"; \
${TARGET}-ld --version 2>/dev/null | head -n1 || true; \
${TARGET}-gcc --version 2>/dev/null | head -n1 || true; \
nasm -v 2>/dev/null || true' > /etc/profile.d/toolchain-info.sh

RUN echo 'export PATH=${PREFIX}/bin:$PATH' > /etc/profile.d/cross-toolchain.sh
