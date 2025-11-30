FROM rockylinux:9

# Install base tooling and bats from EPEL
RUN dnf -y install epel-release \
    && dnf -y install \
        sudo \
        curl \
        wget \
        git \
        vim \
        zsh \
        which \
        gcc \
        make \
        openssl-devel \
        readline-devel \
        zlib-devel \
        bzip2 \
        bzip2-devel \
        sqlite \
        sqlite-devel \
        xz \
        xz-devel \
        bats \
    && dnf clean all

# Ensure wheel group exists and create a test user with sudo privileges
RUN groupadd -r wheel || true
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:testuser" | chpasswd && \
    usermod -aG wheel testuser && \
    echo "%wheel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/wheel && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser && \
    chmod 440 /etc/sudoers.d/wheel /etc/sudoers.d/testuser

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy shell directory contents including all tests
COPY --chown=testuser:testuser ./install.sh ./shell/install.sh
COPY --chown=testuser:testuser ./internal ./shell/internal
COPY --chown=testuser:testuser ./lib ./shell/lib
COPY --chown=testuser:testuser ./README.md ./shell/README.md
COPY --chown=testuser:testuser ./test ./shell/test

# Make scripts executable
RUN chmod +x ./shell/install.sh ./shell/test/test_install.sh ./shell/test/test_units.sh

# Run unit tests BEFORE installation
RUN ./shell/test/test_units.sh

# Run installation and integration tests (needs sudo)
RUN ./shell/test/test_install.sh

# Default command
CMD ["/bin/bash", "-l"]
