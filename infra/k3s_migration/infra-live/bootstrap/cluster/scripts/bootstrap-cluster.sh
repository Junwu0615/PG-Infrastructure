#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo " K3s Cluster Bootstrap"
echo "========================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "[1/7] Check kubectl connectivity..."

kubectl cluster-info >/dev/null

echo "Kubernetes cluster reachable."

echo ""
echo "[2/7] Add Helm repositories..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
#helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo add sealed-secrets https://bitnami.github.io/sealed-secrets
helm repo add argo https://argoproj.github.io/argo-helm

helm repo update

echo ""
echo "[3/7] Install cert-manager..."

kubectl apply -f "${BASE_DIR}/cert-manager/namespace.yaml"

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true \
  -f "${BASE_DIR}/cert-manager/values.yaml"

echo ""
echo "[4/7] Apply cert-manager ClusterIssuer..."

kubectl apply -f "${BASE_DIR}/cert-manager/cluster-issuer.yaml"

echo ""
echo "[5/7] Install sealed-secrets..."

kubectl apply -f "${BASE_DIR}/sealed-secrets/namespace.yaml"

helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace sealed-secrets \
  -f "${BASE_DIR}/sealed-secrets/values.yaml"

echo ""
echo "[6/7] Install ArgoCD..."

kubectl apply -f "${BASE_DIR}/argocd/namespace.yaml"
kubectl apply -f "${BASE_DIR}/argocd/ingress.yaml"

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  -f "${BASE_DIR}/argocd/values.yaml"

echo ""
echo "[7/7] Register GitLab repository secret..."

kubectl apply -f "${BASE_DIR}/argocd/repo-secret.yaml"

echo ""
echo "========================================="
echo " Bootstrap Complete"
echo "========================================="

echo ""
echo "Check cluster status:"
kubectl get pods -A

echo ""
echo "Get ArgoCD service:"
kubectl get svc -n argocd