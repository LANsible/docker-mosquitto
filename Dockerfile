ARG ARCH=amd64
FROM multiarch/alpine:${ARCH}-v3.9 as builder

LABEL maintainer="Wilmar den Ouden" \
    description="Eclipse Mosquitto MQTT Broker, the right way"

ENV VERSION=1.5.8 \
    DOWNLOAD_SHA256=78d7e70c3794dc3a1d484b4f2f8d3addebe9c2da3f5a1cebe557f7d13beb0da4 \
    GPG_KEYS=A0D6EEA1DCAE49A635A3B2F0779B22DFB3E717B7

RUN addgroup -S -g 1883 mosquitto 2>/dev/null && \
    adduser -S -u 1883 -D -H -h /var/empty -s /sbin/nologin -G mosquitto -g mosquitto mosquitto 2>/dev/null

RUN apk --no-cache add \
        build-base \
        cmake \
        gnupg \
        libressl-dev \
        util-linux-dev

RUN wget https://mosquitto.org/files/source/mosquitto-${VERSION}.tar.gz -O /tmp/mosq.tar.gz && \
    echo "$DOWNLOAD_SHA256  /tmp/mosq.tar.gz" | sha256sum -c - && \
    wget https://mosquitto.org/files/source/mosquitto-${VERSION}.tar.gz.asc -O /tmp/mosq.tar.gz.asc && \
    export GNUPGHOME="$(mktemp -d)" && \
    found=''; \
    for server in \
        ha.pool.sks-keyservers.net \
        hkp://keyserver.ubuntu.com:80 \
        hkp://p80.pool.sks-keyservers.net:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $GPG_KEYS from $server"; \
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
    gpg --batch --verify /tmp/mosq.tar.gz.asc /tmp/mosq.tar.gz && \
    gpgconf --kill all && \
    rm -rf "$GNUPGHOME" /tmp/mosq.tar.gz.asc && \
    mkdir -p /build/mosq && \
    tar --strip=1 -xf /tmp/mosq.tar.gz -C /build/mosq && \
    rm /tmp/mosq.tar.gz

RUN make -C /build/mosq -j "$(nproc)" \
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

FROM multiarch/alpine:${ARCH}-v3.9
#FROM scratch

# Copy users from builder
COPY --from=builder \
    /etc/passwd \
    /etc/group \
    /etc/

# Copy mosquitto from builder
COPY --from=builder /build/mosq/src/mosquitto /usr/sbin/mosquitto
COPY --from=builder /build/mosq/src/mosquitto_passwd /usr/sbin/mosquitto_passwd
COPY --from=builder /build/mosq/mosquitto.conf /mosquitto/config/mosquitto.conf

# Copy needed libs from builder
COPY --from=builder \
#    /lib/ld-musl-x86_64.so.1 \
    /usr/lib/libssl.so.45 \
    /usr/lib/libcrypto.so.43 \
    /lib/libuuid.so.1 \
    /lib/

USER mosquitto
ENTRYPOINT ["/usr/sbin/mosquitto"]
CMD ["-c", "/mosquitto/config/mosquitto.conf"]