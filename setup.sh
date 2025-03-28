#!/bin/sh

set -e

######################
# Management Cluster #
######################

# Loging in to ghcr.io
echo "Loging in to ghcr.io"
export AWS_PROFILE=pauvilella # used for Teller to grab the needed secrets from my AWS Secrets Manager
gh_pat=$(teller export json | jq .GITHUB_PAT)
echo $gh_pat | docker login ghcr.io -u pauvilella --password-stdin

# Create kind cluster
echo "Creating Kind local cluster as management cluster..."
kind create cluster --config kind.yaml

# Install flux
echo "Installing flux..."
export GITHUB_TOKEN=$(GH_HOST=github.com gh auth token)
GITHUB_USER="pauvilella"
GITHUB_REPO="crossplane-poc"
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

# Creating AWS Crossplane provider needed creds
echo "Creating AWS Crossplane Provider secret credentials..."
key_id=$(teller export json | jq .CROSSPLANE_AWS_ACCESS_KEY_ID)
secret_key=$(teller export json | jq .CROSSPLANE_AWS_SECRET_ACCESS_KEY)
echo "[default]
aws_access_key_id = $key_id
aws_secret_access_key = $secret_key
" > aws-creds.conf
kubectl --namespace crossplane-system \
  create secret generic aws-creds \
  --from-file creds=./aws-creds.conf
rm ./aws-creds.conf

# Waiting for komoplane to be installed
echo "Waiting for komoplane to be ready..."
kubectl --namespace flux-system wait kustomization/komoplane --for=condition=ready --timeout=5m

# Waiting for crossplane providers to be installed
echo "Waiting for crossplane providers to be ready..."
kubectl --namespace flux-system wait kustomization/crossplane-providers --for=condition=ready --timeout=5m
kubectl wait --for=condition=healthy provider.pkg.crossplane.io --all --timeout=5m

# Waiting for crossplane provider configs to be ready
echo "Waiting for crossplane provider configs to be ready..."
kubectl --namespace flux-system wait kustomization/crossplane-provider-configs --for=condition=ready --timeout=5m

echo "All done! :)"
