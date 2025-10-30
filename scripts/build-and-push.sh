#!/bin/bash
set -e

# Build and push Docker image manually
docker build -t tarboobot/x-host-vps:latest .
docker push tarboobot/x-host-vps:latest

# Also push to GitHub Container Registry if you have access
# docker tag tarboobot/x-host-vps:latest ghcr.io/tarboobot/x-host-vps:latest
# docker push ghcr.io/tarboobot/x-host-vps:latest
