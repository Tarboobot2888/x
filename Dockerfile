# Use Alpine as the base image
FROM alpine:3.22

# Set the PRoot version
ENV PROOT_VERSION=5.4.0

# Set locale
ENV LANG=en_US.UTF-8

# Install necessary packages
RUN apk update && \
    apk add --no-cache \
        bash \
        jq \
        curl \
        ca-certificates \
        iproute2 \
        xz \
        shadow \
        sudo \
        coreutils

# Install PRoot
RUN ARCH=$(uname -m) && \
    mkdir -p /usr/local/bin && \
    proot_url="https://github.com/Tarboobot2888/x/releases/latest/download/proot-${ARCH}-static" && \
    curl -Ls "$proot_url" -o /usr/local/bin/proot && \
    chmod 755 /usr/local/bin/proot

# Create a non-root user and set proper permissions
RUN adduser -D -h /home/container -s /bin/sh container && \
    mkdir -p /home/container && \
    chown -R container:container /home/container

# Switch to the new user
USER container
ENV USER=container
ENV HOME=/home/container

# Set the working directory
WORKDIR /home/container

# Create necessary directories
RUN mkdir -p /home/container/{.cache,.config,.local} && \
    chmod 755 /home/container /home/container/{.cache,.config,.local}

# Copy scripts into the container
COPY --chown=container:container ./scripts/entrypoint.sh /entrypoint.sh
COPY --chown=container:container ./scripts/install.sh /install.sh
COPY --chown=container:container ./scripts/helper.sh /helper.sh
COPY --chown=container:container ./scripts/run.sh /run.sh
COPY --chown=container:container ./scripts/common.sh /common.sh

# Make the copied scripts executable
RUN chmod +x /entrypoint.sh /install.sh /helper.sh /run.sh /common.sh

# Create necessary directories and set permissions
USER root
RUN mkdir -p /mnt /tmp /var/tmp && \
    chmod 1777 /tmp /var/tmp && \
    chown container:container /mnt

USER container

# Set the default command
CMD ["/bin/sh", "/entrypoint.sh"]
