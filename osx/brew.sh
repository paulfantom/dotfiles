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
    logitech-options \
    iterm2

# Basic software
brew install \
    wakeonlan \
    yq \
    git-lfs \
    golang \
    font-sauce-code-pro-nerd-font

git lfs install

# Additional CLI tools replacing old ones
brew install \
    zoxide \
    atuin \
    starship \
    direnv \
    fzf

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

# kubeswitch (kctx/kns): third-party tap, needs explicit trust
brew tap danielfoehrkn/switch
brew trust --formula danielfoehrkn/switch/switch
brew trust --formula danielfoehrkn/switch/switcher
brew install danielfoehrkn/switch/switch

# Cloud tools
brew install \
    awscli \
    azure-cli \
    google-cloud-sdk

# Others
brew install \
    cloudflare/cloudflare/cloudflared \
    minio-mc


