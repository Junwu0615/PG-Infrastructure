#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo " K3s Cluster Bootstrap"
echo "========================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "[1/10] Check kubectl connectivity..."

kubectl cluster-info >/dev/null

echo "Kubernetes cluster reachable."

echo ""
echo "[2/10] Create namespaces..."

kubectl apply -f "${BASE_DIR}/namespaces"

echo ""
echo "[3/10] Add Helm repositories..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo add argo https://argoproj.github.io/argo-helm

helm repo update

echo ""
echo "[4/10] Install ingress-nginx..."

kubectl apply -f "${BASE_DIR}/ingress-nginx/namespace.yaml"

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  -f "${BASE_DIR}/ingress-nginx/values.yaml"

echo ""
echo "[5/10] Install cert-manager..."

kubectl apply -f "${BASE_DIR}/cert-manager/namespace.yaml"

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true \
  -f "${BASE_DIR}/cert-manager/values.yaml"

echo ""
echo "[6/10] Apply cert-manager ClusterIssuer..."

kubectl apply -f "${BASE_DIR}/cert-manager/cluster-issuer.yaml"

echo ""
echo "[7/10] Install sealed-secrets..."

kubectl apply -f "${BASE_DIR}/sealed-secrets/namespace.yaml"

helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace sealed-secrets \
  -f "${BASE_DIR}/sealed-secrets/values.yaml"

echo ""
echo "[8/10] Install ArgoCD..."

kubectl apply -f "${BASE_DIR}/argocd/namespace.yaml"

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  -f "${BASE_DIR}/argocd/values.yaml"

echo ""
echo "[9/10] Register GitLab repository secret..."

kubectl apply -f "${BASE_DIR}/argocd/repo-secret.yaml"

echo ""
echo "[10/10] Bootstrap GitOps Root App..."

kubectl apply -f "${BASE_DIR}/argocd/root-app.yaml"

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