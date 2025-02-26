#!/bin/sh

set -e

######################
# Management Cluster #
######################

# Create kind cluster
echo "Creating Kind local cluster as management cluster..."
kind create cluster --config kind.yaml

# Install flux
echo "Installing flux..."
export GITHUB_TOKEN=$(GH_HOST=github.com gh auth token)
read -p "Enter GitHub username [default: pauvilella]: " GITHUB_USER
read -p "Enter GitHub repo [default: crossplane-poc]: " GITHUB_REPO
GITHUB_USER=${GITHUB_USER:-"pauvilella"}
GITHUB_REPO=${GITHUB_REPO:-"crossplane-poc"}
flux bootstrap github \
  --branch=main \
  --context=kind-kind \
  --hostname=github.com \
  --interval=1m0s \
  --watch-all-namespaces=true \
  --owner=${GITHUB_USER} \
  --path=./clusters/kind-kind \
  --repository=${GITHUB_REPO}

# Waiting for ingress-nginx to be installed
echo "Waiting for ingress-nginx to be ready..."
kubectl --namespace flux-system wait kustomization/ingress-nginx --for=condition=ready --timeout=5m

# Waiting for crossplane to be installed
echo "Waiting for crossplane to be ready..."
kubectl --namespace flux-system wait kustomization/crossplane --for=condition=ready --timeout=5m

# Waiting for crossplane to be installed
echo "Waiting for crossplane providers to be ready..."
kubectl --namespace flux-system wait kustomization/crossplane-providers --for=condition=ready --timeout=5m
kubectl wait --for=condition=healthy provider.pkg.crossplane.io --all --timeout=5m
