# Cronicle - Multi-Server Task Scheduler and Runner
# Hardened, rootless Docker image based on Ubuntu LTS

#############################################
# Stage 1: Builder
#############################################
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    gnupg2 \
    build-essential \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js for building Cronicle
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Build Cronicle
WORKDIR /tmp/cronicle-build
RUN git clone https://github.com/jhuckaby/Cronicle.git . && \
    npm install && \
    npm install nodemailer@7.0.11 && \
    node bin/build.js dist && \
    rm -rf .git && \
    npm cache clean --force

#############################################
# Stage 2: Final Runtime Image
#############################################
FROM ubuntu:24.04

# Metadata
LABEL maintainer="xentropics"
LABEL description="Cronicle scheduler - hardened and rootless"
LABEL version="1.3.1"

ARG DEBIAN_FRONTEND=noninteractive

# Security hardening - kernel parameters and system settings
RUN echo "umask 0027" >> /etc/bash.bashrc && \
    echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf && \
    echo "kernel.dmesg_restrict = 1" >> /etc/sysctl.conf && \
    echo "kernel.kptr_restrict = 2" >> /etc/sysctl.conf

# Update system and install RUNTIME dependencies only
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    perl \
    procps \
    gnupg2 \
    jq \
    python3-venv \
    python3-pip \
    unattended-upgrades \
    apt-listchanges \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

# Install Node.js runtime (required for Cronicle)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Upgrade Python packages to fix vulnerabilities (setuptools only, pip can't be upgraded via pip itself)
RUN pip3 install --break-system-packages --upgrade setuptools==78.1.1

# Verify Python venv is available for Cronicle jobs
RUN python3 -m venv --help > /dev/null && echo "✓ python3-venv installed successfully"

# Create non-root user for running Cronicle
RUN groupadd -r -g 3012 cronicle && \
    useradd -r -u 3012 -g cronicle -m -d /opt/cronicle -s /sbin/nologin cronicle && \
    passwd -l cronicle

# Copy built Cronicle from builder stage
COPY --from=builder --chown=cronicle:cronicle /tmp/cronicle-build /opt/cronicle

WORKDIR /opt/cronicle

# Create directories and apply security hardening in combined layers
RUN mkdir -p /opt/cronicle/data /opt/cronicle/logs /opt/cronicle/plugins \
    /opt/cronicle/workloads /opt/cronicle/tmp /opt/cronicle/queue && \
    chown -R cronicle:cronicle /opt/cronicle/data /opt/cronicle/logs \
    /opt/cronicle/plugins /opt/cronicle/workloads /opt/cronicle/tmp /opt/cronicle/queue && \
    chmod 750 /opt/cronicle/data /opt/cronicle/logs /opt/cronicle/plugins /opt/cronicle/tmp && \
    chmod 755 /opt/cronicle/workloads

# Security hardening - combined layer for efficiency
RUN find / -xdev -type f -perm -4000 -exec chmod u-s {} \; 2>/dev/null || true && \
    find / -xdev -type f -perm -2000 -exec chmod g-s {} \; 2>/dev/null || true && \
    sed -i -r '/^(root|cronicle)/!s#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd && \
    passwd -l root 2>/dev/null || true && \
    chmod 700 /root && \
    chmod 750 /opt/cronicle && \
    chmod 1777 /tmp && \
    chmod 1777 /var/tmp && \
    rm -f /usr/bin/wget /usr/bin/nc /usr/bin/netcat /bin/nc \
    /usr/bin/telnet /usr/bin/ftp 2>/dev/null || true && \
    rm -rf /var/log/* /usr/share/doc/* /usr/share/man/* \
    /usr/share/info/* /usr/share/locale/* /var/cache/debconf/*

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
