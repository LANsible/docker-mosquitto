FROM alpine:3.10 as builder

ENV VERSION=v.1.6.8

# Add unprivileged user
RUN echo "mosquitto:x:1000:1000:mosquitto:/:" > /etc_passwd

RUN apk --no-cache add \
        git \
        build-base \
        openssl-dev

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/eclipse/mosquitto.git /mosquitto

WORKDIR /mosquitto

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
# WITH_MEMORY_TRACKING: disable to use less memory and less cpu
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
    export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
    make \
      CFLAGS="-Wall -O3 -static" \
      LDFLAGS="-static" \
      WITH_STATIC_LIBRARIES=yes \
      WITH_SHARED_LIBRARIES=no \
      WITH_MEMORY_TRACKING=no \
      WITH_WEBSOCKETS=no \
      binary

# Minify binaries
# --brute does not work
RUN apk add --no-cache upx && \
    upx --best /mosquitto/src/mosquitto

FROM scratch

# Copy the unprivileged user
COPY --from=builder /etc_passwd /etc/passwd

# Copy static binary
COPY --from=builder /mosquitto/src/mosquitto /mosquitto
COPY --from=builder /mosquitto/mosquitto.conf /config/mosquitto.conf

USER mosquitto
ENTRYPOINT ["/mosquitto"]
CMD ["-c", "/config/mosquitto.conf"]
