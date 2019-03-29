ARG ARCH=amd64
FROM multiarch/alpine:${ARCH}-v3.9 as builder

LABEL maintainer="Wilmar den Ouden" \
    description="Eclipse Mosquitto MQTT Broker, the right way"

ARG VERSION=master

RUN addgroup -S -g 1883 mosquitto 2>/dev/null && \
    adduser -S -u 1883 -D -H -h /var/empty -s /sbin/nologin -G mosquitto -g mosquitto mosquitto 2>/dev/null

RUN apk --no-cache add \
        git \
        build-base \
        cmake \
        gnupg \
        libressl-dev \
        util-linux-dev

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/eclipse/mosquitto.git /mosquitto

RUN make -C /mosquitto -j "$(nproc)" \
        CFLAGS="-Wall -O2" \
        WITH_ADNS=no \
        WITH_DOCS=no \
        WITH_MEMORY_TRACKING=no \
        WITH_STATIC_LIBRARIES=yes \
        WITH_SHARED_LIBRARIES=no \
        WITH_SRV=no \
        WITH_STRIP=yes \
        WITH_TLS_PSK=yes \
        WITH_WEBSOCKETS=no \
        WITH_UUID=yes \
        prefix=/usr \
        binary

# Minify binaries
COPY --from=lansible/upx:3.95 /usr/bin/upx /usr/bin/upx
RUN upx --best /mosquitto/src/mosquitto

FROM multiarch/alpine:${ARCH}-v3.9

# Copy users from builder
COPY --from=builder \
    /etc/passwd \
    /etc/group \
    /etc/

# Copy mosquitto from builder
COPY --from=builder /mosquitto/src/mosquitto /usr/sbin/mosquitto
COPY --from=builder /mosquitto/mosquitto.conf /mosquitto/mosquitto.conf

# Copy needed libs from builder
COPY --from=builder \
    /usr/lib/libssl.so.45 \
    /usr/lib/libcrypto.so.43 \
    /lib/libuuid.so.1 \
    /lib/

USER mosquitto
ENTRYPOINT ["/usr/sbin/mosquitto"]
CMD ["-c", "/mosquitto/mosquitto.conf"]