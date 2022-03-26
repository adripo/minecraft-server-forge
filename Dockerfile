FROM alpine:3.15

# ARG values
ARG BUILD_DATE
ARG MC_VERSION
ARG DW_LINK
ARG MC_SERVER="minecraft_server.${MC_VERSION}"

# Set version for s6 overlay
ARG S6_OVERLAY_VERSION="3.1.0.1"
ARG OVERLAY_ARCH="amd64"

# ARG - ENV
# Absolute path of app directory
ARG APP_DIR="/app"
ENV APP_DIR="${APP_DIR}"

# Absolute path of data directory
ARG DATA_DIR="/data"
ENV DATA_DIR="${DATA_DIR}"

# Absolute path of STDIN fifo pipe
ARG STDIN_PIPE="${APP_DIR}/in"
ENV STDIN_PIPE="${STDIN_PIPE}"

# ENV default values
ENV JVM_XMS=1G
ENV JVM_XMX=4G
ENV PUID=1000
ENV PGID=1000

# Labels
LABEL build_version="Minecraft Server version: ${MC_VERSION} Build-date: ${BUILD_DATE}"
LABEL maintainer="adripo"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.authors="adripo"
LABEL org.opencontainers.image.url="https://github.com/adripo/minecraft-server/blob/main/README.md"
LABEL org.opencontainers.image.source="https://github.com/adripo/minecraft-server"
LABEL org.opencontainers.image.version="${MC_VERSION}"
LABEL org.opencontainers.image.title="Minecraft Server"
LABEL org.opencontainers.image.description="Minecraft Server wrapped in a Docker image"


# Install dependencies
RUN echo "**** install runtime packages ****" && \
    apk add --no-cache \
      bash \
      shadow \
      curl \
      tzdata \
      openjdk17

# Add s6 overlay-noarch
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
RUN rm -f /tmp/s6-overlay-noarch.tar.xz
# Add s6 overlay-x86_64
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
RUN rm -f /tmp/s6-overlay-x86_64.tar.xz


# Create abc user
RUN echo "**** create abc user and group ****" && \
    addgroup -g $PGID abc && \
    adduser -u $PUID -G abc -h $APP_DIR -D abc

# Create data dir
RUN mkdir -p $DATA_DIR
RUN chown abc:abc $DATA_DIR

# Add local files
COPY root/ /


USER abc
WORKDIR $APP_DIR

# Setup server
RUN echo "**** setup server ****"
COPY --chown=abc:abc server-setup.sh .
RUN chmod +x server-setup.sh
RUN ./server-setup.sh
RUN rm -f server-setup.sh

# Cleanup
RUN rm -rf /tmp/*

## Copy startup script
#RUN echo "**** setup startup ****"
#COPY --chown=abc:abc docker-startup.sh .
#RUN chmod +x docker-startup.sh

# Volume mount point
VOLUME $DATA_DIR

# Expose port
EXPOSE 25565

USER root

# Startup
ENTRYPOINT ["/init"]
#CMD ["./docker-startup.sh"]