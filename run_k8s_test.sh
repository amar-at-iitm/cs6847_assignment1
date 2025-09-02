#!/bin/bash

set -euo pipefail

# Constants
APP_NAME="flask-app"
NAMESPACE="default"
RESULTS_DIR="results"
DURATION_SHORT=5
DURATION_LONG=2
RATE_LOW=10
RATE_HIGH=10000

echo "[INFO] Starting Minikube..."
minikube start

echo "[INFO] Setting Docker env to use Minikube's Docker daemon..."
eval "$(minikube docker-env)"

echo "[INFO] Building Docker image..."
docker build -t ${APP_NAME}:latest app/

echo "[INFO] Applying Kubernetes manifests..."
kubectl apply -f kubernetes/

echo "[INFO] Waiting for pods to become ready..."
kubectl wait --for=condition=Ready pod -l app=flask-app --timeout=120s

echo "[INFO] Checking Kubernetes resources..."
kubectl get pods
kubectl get svc
kubectl get hpa

echo "[INFO] Waiting for service to become available..."
sleep 5  # can be replaced with a readiness check

# Start tunnel in background and capture URL
(minikube service flask-service --url > svc_url.txt 2>/dev/null &)
sleep 5
K8S_URL=$(cat svc_url.txt | head -n1)

echo "[INFO] Service is available at ${K8S_URL}"


mkdir -p "${RESULTS_DIR}"

echo "[INFO] Running low-load test (rate=${RATE_LOW}, duration=${DURATION_SHORT}s)..."
python3 client/client.py --target "${K8S_URL}" --rate ${RATE_LOW} \
  --output "${RESULTS_DIR}/kubernetes_response_${RATE_LOW}" \
  --duration ${DURATION_SHORT}

echo "[INFO] Running high-load test (rate=${RATE_HIGH}, duration=${DURATION_LONG}s)..."
python3 client/client.py --target "${K8S_URL}" --rate ${RATE_HIGH} \
  --output "${RESULTS_DIR}/kubernetes_response_${RATE_HIGH}" \
  --duration ${DURATION_LONG}

echo "[INFO] All Kubernetes tests done. Results saved in ./${RESULTS_DIR}/"

echo "[INFO] Cleaning up Kubernetes resources..."
kubectl delete -f kubernetes/

echo "[INFO] Stopping Minikube..."
minikube stop

echo "[INFO] All services stopped."
