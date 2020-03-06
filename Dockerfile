#######################################################################################################################
# Build static Mosquitto
#######################################################################################################################
ARG ARCHITECTURE
FROM multiarch/alpine:${ARCHITECTURE}-v3.11 as builder

ENV VERSION=v1.6.9

# Add unprivileged user
RUN echo "mosquitto:x:1000:1000:mosquitto:/:" > /etc_passwd

RUN apk --no-cache add \
        git \
        build-base \
        openssl-dev \
        openssl-libs-static \
        libwebsockets-dev

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/eclipse/mosquitto.git /mosquitto

WORKDIR /mosquitto

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
# WITH_STATIC_LIBRARIES default no, needed for static compile
# WITH_SHARED_LIBRARIES default yes, needs to be no for static compile
# WITH_MEMORY_TRACKING: disable to use less memory and less cpu
# WITH_ADNS: disable GNU adns support
# WITH_SRV: only used by the client https://www.eclipse.org/lists/mosquitto-dev/msg01391.html
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
    export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
    make \
      CFLAGS="-Wall -O3 -static" \
      LDFLAGS="-static" \
      WITH_STATIC_LIBRARIES=yes \
      WITH_SHARED_LIBRARIES=no \
      WITH_MEMORY_TRACKING=no \
      WITH_WEBSOCKETS=yes \
      WITH_ADNS=no \
      WITH_SRV=no \
      binary

# Minify binaries
# --brute does not work
RUN apk add --no-cache upx && \
    upx --best /mosquitto/src/mosquitto && \
    upx -t /mosquitto/src/mosquitto


#######################################################################################################################
# Final scratch image
#######################################################################################################################
FROM scratch

# Add description
LABEL org.label-schema.description="Static compiled Mosquitto in a scratch container"

# Copy the unprivileged user
COPY --from=builder /etc_passwd /etc/passwd

# Copy static binary
COPY --from=builder /mosquitto/src/mosquitto /mosquitto

# Add default configuration
COPY --from=builder /mosquitto/mosquitto.conf /config/mosquitto.conf

USER mosquitto
ENTRYPOINT ["/mosquitto"]
CMD ["-c", "/config/mosquitto.conf"]
EXPOSE 1883
