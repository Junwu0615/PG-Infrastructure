#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo " K3s Cluster Bootstrap"
echo "========================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "[1/9] Check kubectl connectivity..."

kubectl cluster-info >/dev/null

echo "Kubernetes cluster reachable."

echo ""
echo "[2/9] Create namespaces..."

kubectl apply -f "${BASE_DIR}/namespaces"

echo ""
echo "[3/9] Add Helm repositories..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo add argo https://argoproj.github.io/argo-helm

helm repo update

echo ""
echo "[4/9] Install ingress-nginx..."

kubectl apply -f "${BASE_DIR}/ingress-nginx/namespace.yaml"

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  -f "${BASE_DIR}/ingress-nginx/values.yaml"

echo ""
echo "[5/9] Install cert-manager..."

kubectl apply -f "${BASE_DIR}/cert-manager/namespace.yaml"

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true \
  -f "${BASE_DIR}/cert-manager/values.yaml"

echo ""
echo "[6/9] Apply cert-manager ClusterIssuer..."

kubectl apply -f "${BASE_DIR}/cert-manager/cluster-issuer.yaml"

echo ""
echo "[7/9] Install sealed-secrets..."

kubectl apply -f "${BASE_DIR}/sealed-secrets/namespace.yaml"

helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace sealed-secrets \
  -f "${BASE_DIR}/sealed-secrets/values.yaml"

echo ""
echo "[8/9] Install ArgoCD..."

kubectl apply -f "${BASE_DIR}/argocd/namespace.yaml"
kubectl apply -f "${BASE_DIR}/argocd/ingress.yaml"

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  -f "${BASE_DIR}/argocd/values.yaml"

echo ""
echo "[9/9] Register GitLab repository secret..."

kubectl apply -f "${BASE_DIR}/argocd/repo-secret.yaml"

echo ""
echo "========================================="
echo " Bootstrap Complete"
echo "========================================="

echo ""
echo "Check cluster status:"
kubectl get pods -A

echo ""
echo "Get ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

echo ""
echo "Get ArgoCD service:"
kubectl get svc -n argocd