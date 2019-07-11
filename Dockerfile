FROM alpine:3.10 as builder

ARG VERSION=master

LABEL maintainer="wilmardo" \
      description="Eclipse Mosquitto MQTT Broker, the right way"

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
# --brute does not work
RUN apk add --no-cache upx && \
    upx --best /mosquitto/src/mosquitto

FROM alpine:3.10

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