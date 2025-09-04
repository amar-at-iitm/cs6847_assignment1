#!/bin/bash

set -euo pipefail

APP_NAME="flask-app"
SERVICE_NAME="flask-service"
RESULTS_DIR="results"
K8S_NAMESPACE="default"
RATE_LOW=10
RATE_HIGH=10000
DURATION_SHORT=5
DURATION_LONG=2
PROVIDED_IP="127.0.0.1"    # Replace with PROVIDED IP
PROVIDED_PORT="5000"        # Replace with PROVIDED PORT

mkdir -p "${RESULTS_DIR}"

echo "======================="
echo "=== Docker Swarm Test ==="
echo "======================="

echo "[SWARM] Building Docker image..."
docker build -t ${APP_NAME}:latest app/

echo "[SWARM] Initializing Swarm..."
docker swarm init || echo "[WARN] Swarm already initialized."

echo "[SWARM] Deploying service..."
docker service create \
  --name ${SERVICE_NAME} \
  --replicas 3 \
  -p 5000:5000 \
  ${APP_NAME}:latest

echo "[SWARM] Waiting for service to stabilize..."
sleep 10  # Can be replaced this with a readiness check

echo "[SWARM] Running test (basic curl)..."
curl -s http://127.0.0.1:5000 || echo "[WARN] Swarm service may not have started yet"



mkdir -p "${RESULTS_DIR}"

echo "[INFO] Running low-load test (rate=10, duration=${DURATION_SHORT}s)..."
python3 client/client.py --target "http://127.0.0.1:5000" --rate ${RATE_LOW} \
  --duration ${DURATION_SHORT} \
  --output "${RESULTS_DIR}/docker_response_${RATE_LOW}" \
  --mode sync
     

echo "[INFO] Running high-load test (rate=10000, duration=${DURATION_LONG}s)..."
python3 client/client.py --target "http://127.0.0.1:5000" --rate ${RATE_HIGH} \
  --output "${RESULTS_DIR}/docker_response_${RATE_HIGH}" \
  --duration ${DURATION_LONG} \
  --mode sync \
  --upload_url http://${PROVIDED_IP}:${PROVIDED_PORT}/

echo "[INFO] Docker Swarm tests done. Results saved in ./${RESULTS_DIR}/"


echo "[SWARM] Cleaning up..."
docker service rm ${SERVICE_NAME}
docker swarm leave --force

echo "[SWARM] Docker Swarm test complete."
echo

echo "==========================="
echo "=== Kubernetes Test (Minikube) ==="
echo "==========================="

echo "[K8S] Starting Minikube..."
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
  --duration ${DURATION_SHORT} \
  --upload_url http://${PROVIDED_IP}:${PROVIDED_PORT}/

echo "[INFO] Running high-load test (rate=${RATE_HIGH}, duration=${DURATION_LONG}s)..."
python3 client/client.py --target "${K8S_URL}" --rate ${RATE_HIGH} \
  --output "${RESULTS_DIR}/kubernetes_response_${RATE_HIGH}" \
  --duration ${DURATION_LONG} \
  --upload_url http://${PROVIDED_IP}:${PROVIDED_PORT}/

echo "[INFO] All Kubernetes tests done. Results saved in ./${RESULTS_DIR}/"

echo "[INFO] Cleaning up Kubernetes resources..."
kubectl delete -f kubernetes/

echo "[INFO] Stopping Minikube..."
minikube stop

echo "[INFO] All services stopped."
echo "==========================="
echo "=== All Tests Completed ==="
