FROM debian:trixie-slim AS toolchain_builder

ARG SPIKE_REF=19609434bb3d83448eec8796e8f0367c868efbda
ARG PK_REF=9c61d29846d8521d9487a57739330f9682d5b542
ENV RISCV=/opt/riscv
ENV PATH=/opt/riscv/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git build-essential autoconf automake libtool pkg-config \
    device-tree-compiler libboost-regex-dev libboost-system-dev \
    gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf \
    picolibc-riscv64-unknown-elf \
    && rm -rf /var/lib/apt/lists/*

ARG BUILD_JOBS=2
RUN git clone --filter=blob:none https://github.com/riscv-software-src/riscv-isa-sim.git /tmp/riscv-isa-sim \
    && git -C /tmp/riscv-isa-sim checkout "$SPIKE_REF" \
    && mkdir /tmp/riscv-isa-sim/build \
    && cd /tmp/riscv-isa-sim/build \
    && ../configure --prefix="$RISCV" \
    && make -j"$BUILD_JOBS" && make install \
    && rm -rf /tmp/riscv-isa-sim

RUN git clone --filter=blob:none https://github.com/riscv-software-src/riscv-pk.git /tmp/riscv-pk \
    && git -C /tmp/riscv-pk checkout "$PK_REF" \
    && mkdir /tmp/riscv-pk/build \
    && cd /tmp/riscv-pk/build \
    && CC='riscv64-unknown-elf-gcc --specs=picolibc.specs' ../configure --prefix="$RISCV" --host=riscv64-unknown-elf --with-arch=rv64gc_zifencei \
    && make -j"$BUILD_JOBS" && make install \
    && ln -s "$RISCV/riscv64-unknown-elf/bin/pk" "$RISCV/bin/pk" \
    && rm -rf /tmp/riscv-pk

RUN strip --strip-unneeded "$RISCV/bin/spike"

FROM debian:trixie-slim
ENV RISCV=/opt/riscv
ENV PATH=/opt/riscv/bin:${PATH}
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu libc6-dev-riscv64-cross \
    qemu-user libstdc++6 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=toolchain_builder /opt/riscv/bin/spike /opt/riscv/bin/spike
COPY --from=toolchain_builder /opt/riscv/riscv64-unknown-elf/bin/pk /opt/riscv/bin/pk

RUN spike --help >/dev/null 2>&1 \
    && riscv64-linux-gnu-gcc --version \
    && qemu-riscv64 --version \
    && test -x "$RISCV/bin/pk"
