# Cronicle - Multi-Server Task Scheduler and Runner
# Hardened, rootless Docker image based on Ubuntu LTS

# Use Ubuntu LTS as base image
FROM ubuntu:22.04

# Metadata
LABEL maintainer="xentropics"
LABEL description="Cronicle scheduler - hardened and rootless"
LABEL version="1.0"

# Build arguments for enhanced security
ARG DEBIAN_FRONTEND=noninteractive

# Security hardening - kernel parameters and system settings
RUN echo "umask 0027" >> /etc/bash.bashrc && \
    echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf && \
    echo "kernel.dmesg_restrict = 1" >> /etc/sysctl.conf && \
    echo "kernel.kptr_restrict = 2" >> /etc/sysctl.conf

# Update system and install minimal dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    perl \
    procps \
    gnupg2 \
    unattended-upgrades \
    apt-listchanges \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/*

# Configure unattended-upgrades for automatic security updates
RUN echo 'Unattended-Upgrade::Allowed-Origins {\n\
    "${distro_id}:${distro_codename}-security";\n\
};\n\
Unattended-Upgrade::AutoFixInterruptedDpkg "true";\n\
Unattended-Upgrade::MinimalSteps "true";\n\
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";\n\
Unattended-Upgrade::Remove-Unused-Dependencies "true";\n\
Unattended-Upgrade::Automatic-Reboot "false";\n' \
    > /etc/apt/apt.conf.d/50unattended-upgrades && \
    echo 'APT::Periodic::Update-Package-Lists "1";\n\
APT::Periodic::Download-Upgradeable-Packages "1";\n\
APT::Periodic::AutocleanInterval "7";\n\
APT::Periodic::Unattended-Upgrade "1";\n' \
    > /etc/apt/apt.conf.d/20auto-upgrades

# Install Node.js (required for Cronicle) with signature verification
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/*

# Create non-root user for running Cronicle with restricted permissions
RUN groupadd -r -g 1000 cronicle && \
    useradd -r -u 1000 -g cronicle -m -d /opt/cronicle -s /sbin/nologin cronicle && \
    passwd -l cronicle

# Security hardening - remove unnecessary packages and services
RUN apt-get purge -y --auto-remove \
    && rm -rf /var/log/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/info/* \
    && rm -rf /usr/share/locale/* \
    && rm -rf /var/cache/debconf/*

# Download and install Cronicle as cronicle user
USER cronicle
WORKDIR /tmp/cronicle-build
RUN git clone https://github.com/jhuckaby/Cronicle.git . && \
    npm install && \
    node bin/build.js dist

# Move to final location as root
USER root
RUN cp -a /tmp/cronicle-build/. /opt/cronicle/ && \
    rm -rf /tmp/cronicle-build && \
    chown -R cronicle:cronicle /opt/cronicle

WORKDIR /opt/cronicle

WORKDIR /opt/cronicle

# Create directories for data, logs, and plugins
RUN mkdir -p /opt/cronicle/data /opt/cronicle/logs /opt/cronicle/plugins /opt/cronicle/workloads /opt/cronicle/tmp /opt/cronicle/queue && \
    chown -R cronicle:cronicle /opt/cronicle/data /opt/cronicle/logs /opt/cronicle/plugins /opt/cronicle/workloads /opt/cronicle/tmp /opt/cronicle/queue

# Security hardening - remove unnecessary setuid/setgid binaries
RUN find / -xdev -type f -perm -4000 -exec chmod u-s {} \; 2>/dev/null || true && \
    find / -xdev -type f -perm -2000 -exec chmod g-s {} \; 2>/dev/null || true

# Security hardening - remove shells from system users and lock accounts
RUN sed -i -r '/^(root|cronicle)/!s#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd && \
    passwd -l root 2>/dev/null || true

# Security hardening - restrict file permissions
RUN chmod 700 /root && \
    chmod 750 /opt/cronicle && \
    chmod 1777 /tmp && \
    chmod 1777 /var/tmp

# Security hardening - remove unnecessary binaries and tools that could aid attackers
RUN rm -f /usr/bin/wget /usr/bin/nc /usr/bin/netcat /bin/nc 2>/dev/null || true && \
    rm -f /usr/bin/telnet /usr/bin/ftp 2>/dev/null || true

# Security hardening - restrict directory permissions
RUN chmod 750 /opt/cronicle/data /opt/cronicle/logs /opt/cronicle/plugins && \
    chmod 755 /opt/cronicle/workloads && \
    mkdir -p /opt/cronicle/tmp && \
    chmod 750 /opt/cronicle/tmp && \
    chown cronicle:cronicle /opt/cronicle/tmp

# Security hardening - remove package manager caches and git history
RUN rm -rf /opt/cronicle/.git && \
    npm cache clean --force 2>/dev/null || true

# Copy configuration scripts
COPY --chown=cronicle:cronicle entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER cronicle

# Expose ports
# 3012 - Web UI
EXPOSE 3012

# Volumes for persistence
VOLUME ["/opt/cronicle/data", "/opt/cronicle/logs", "/opt/cronicle/plugins", "/opt/cronicle/workloads"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3012/ || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start"]
