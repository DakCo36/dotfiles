FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic tools
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    wget \
    git \
    vim \
    zsh \
    build-essential \
    software-properties-common \
    locales \
    bats \
    && rm -rf /var/lib/apt/lists/*

# Create a test user with sudo privileges
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:testuser" | chpasswd && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser && \
    chmod 440 /etc/sudoers.d/testuser

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
