#!/bin/sh

# Install software using brew

# GUI software
brew install --cask rectangle arc MonitorControl steam signal

# Basic software
brew install \
    strace \
    convert \
    wakeonlan \
    yq \
    git-lfs \
    golang

# Infra-as-code
brew install \
    terraform \
    terragrunt \
    ansible \
    molecule

# Monitoring tools
brew install \
    prometheus \
    alertmanager \
    pint \
    jsonnet \
    jsonnet-bundler \
    thanos

# Kubernetes
brew install \
    istioctl \
    cilium-cli \
    pluto \
    fleet-cli \
    argocd \
    derailed/popeye/popeye \
    kind \
    chart-testing

# Cloud tools
brew install \
    aksctl \
    awscli \
    azure-cli \
    gcloud \
    gke-gcloud-auth-plugin \
    gkectl

# Others
brew install \
    cloudflare/cloudflare/cloudflared \
    minio-mc
