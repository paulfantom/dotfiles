#!/bin/sh

# Install software using brew
set -euo pipefail

# GUI software
brew install --cask \
    rectangle \
    arc \
    MonitorControl \
    steam \
    signal \
    logitech-options

# Basic software
brew install \
    wakeonlan \
    yq \
    git-lfs \
    golang

git lfs install

# Infra-as-code
brew install \
    terraform \
    terragrunt \
    ansible \
    ansible-lint \
    molecule

# Monitoring tools
brew install \
    prometheus \
    pint \
    jsonnet \
    jsonnet-bundler \
    thanos

# Kubernetes
brew install \
    kubernetes-cli \
    krew \
    helm \
    istioctl \
    cilium-cli \
    pluto \
    fleet-cli \
    argocd \
    derailed/popeye/popeye \
    kind \
    chart-testing \
    rancher-cli

# Cloud tools
brew install \
    awscli \
    azure-cli \
    google-cloud-sdk

# Others
brew install \
    cloudflare/cloudflare/cloudflared \
    minio-mc
