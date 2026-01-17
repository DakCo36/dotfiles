FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic tools
RUN apt-get update && apt-get install -y \
  sudo \
  curl \
  build-essential \
  software-properties-common \
  locales \
  bats \
  git \
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

# Copy setup directory contents including all tests
COPY --chown=testuser:testuser ./install.sh ./setup/install.sh
COPY --chown=testuser:testuser ./internal ./setup/internal
COPY --chown=testuser:testuser ./lib ./setup/lib
COPY --chown=testuser:testuser ./README.md ./setup/README.md
COPY --chown=testuser:testuser ./test ./setup/test

# Make scripts executable
RUN chmod +x ./setup/install.sh ./setup/test/test_install.sh ./setup/test/test_units.sh

# Run unit tests BEFORE installation
RUN ./setup/test/test_units.sh

# # Run installation and integration tests (needs sudo)
RUN ./setup/test/test_install.sh

# Default command
CMD ["/bin/bash", "-l"]
