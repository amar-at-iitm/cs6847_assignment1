#!/bin/bash

set -euo pipefail

# Constants
ROLL_NUMBER="MA24M002"
APP_NAME="flask-app"
NAMESPACE="default"
RESULTS_DIR="results"
DURATION_SHORT=5
DURATION_LONG=2
RATE_LOW=10
RATE_HIGH=10000

########################################################################
PROVIDED_IP="XXX.X.X.X"       # Replace with PROVIDED IP
PROVIDED_PORT="XXXX"          # Replace with PROVIDED PORT
########################################################################


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
# Build command dynamically
CMD="python3 client/client.py --target \"${K8S_URL}\" \
  --rate ${RATE_LOW} \
  --output \"${RESULTS_DIR}/${ROLL_NUMBER}kubernetes${RATE_LOW}.txt\" \
  --duration ${DURATION_SHORT} \
  --mode sync"

# Only add --upload_url if PROVIDED_IP and PROVIDED_PORT are not placeholders
if [[ "${PROVIDED_IP}" != "XXX.X.X.X" && "${PROVIDED_PORT}" != "XXXX" ]]; then
  CMD+=" --upload_url http://${PROVIDED_IP}:${PROVIDED_PORT}/"
fi

# Execute the command
eval $CMD

echo "[INFO] Running high-load test (rate=${RATE_HIGH}, duration=${DURATION_LONG}s)..."
# Build command dynamically
CMD="python3 client/client.py --target \"${K8S_URL}\" \
  --rate ${RATE_HIGH} \
  --output \"${RESULTS_DIR}/${ROLL_NUMBER}kubernetes${RATE_HIGH}.txt\" \
  --duration ${DURATION_LONG} \
  --mode sync"

# Only add --upload_url if PROVIDED_IP and PROVIDED_PORT are not placeholders
if [[ "${PROVIDED_IP}" != "XXX.X.X.X" && "${PROVIDED_PORT}" != "XXXX" ]]; then
  CMD+=" --upload_url http://${PROVIDED_IP}:${PROVIDED_PORT}/"
fi

# Execute the command
eval $CMD

echo "[INFO] All Kubernetes tests done. Results saved in ./${RESULTS_DIR}/"

echo "[INFO] Cleaning up Kubernetes resources..."
kubectl delete -f kubernetes/

echo "[INFO] Stopping Minikube..."
minikube stop

echo "[INFO] All services stopped."
