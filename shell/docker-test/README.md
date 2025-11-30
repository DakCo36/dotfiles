# Shell Docker Test Images

Build Docker images to validate the shell installer across supported distributions. Each Dockerfile runs unit tests and the full installation flow inside a clean container.

## Available images
- `docker-test/ubuntu.Dockerfile` (Ubuntu 20.04)
- `docker-test/rocky.Dockerfile` (Rocky Linux 9)
- `docker-test/opensuse.Dockerfile` (openSUSE Leap 15.6)

## Build images
From the `shell` directory, pass one or more distro names that match the Dockerfile basenames:

```bash
./docker-test.sh ubuntu
./docker-test.sh rocky opensuse
```

To build every available image in sequence, use `--all`:

```bash
./docker-test.sh --all
```

Successful builds indicate the installer and tests completed without errors.
