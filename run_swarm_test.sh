
#!/bin/bash

set -euo pipefail

APP_NAME="flask-app"
SERVICE_NAME="flask-service"
RESULTS_DIR="results"
DURATION_SHORT=5
DURATION_LONG=2
RATE_LOW=10
RATE_HIGH=10000
PROVIDED_IP="127.0.0.1"       # Replace with PROVIDED IP
PROVIDED_PORT="5000"          # Replace with PROVIDED PORT

echo "[INFO] Building Docker image..."
docker build -t ${APP_NAME}:latest app/

echo "[INFO] Initializing Docker Swarm..."
docker swarm init || echo "[WARN] Swarm already initialized."

echo "[INFO] Deploying Swarm service..."
docker service create \
  --name ${SERVICE_NAME} \
  --replicas 3 \
  -p 5000:5000 \
  ${APP_NAME}:latest

echo "[INFO] Waiting for service to stabilize..."
sleep 10  # Optional: Replace with a proper health check if needed


echo "[SWARM] Running test (basic curl)..."
curl -s http://127.0.0.1:5000 || echo "[WARN] Swarm service may not have started yet"
# Insert commands here, e.g.: "curl http://127.0.0.1:5000"



mkdir -p "${RESULTS_DIR}"

echo "[INFO] Running low-load test (rate=10, duration=${DURATION_SHORT}s)..."
python3 client/client.py --target "http://127.0.0.1:5000" --rate ${RATE_LOW} \
  --duration ${DURATION_SHORT} \
  --output "${RESULTS_DIR}/docker_response_10" \
  --mode sync
     

echo "[INFO] Running high-load test (rate=10000, duration=${DURATION_LONG}s)..."
python3 client/client.py --target "http://127.0.0.1:5000" --rate ${RATE_HIGH} \
  --output "${RESULTS_DIR}/docker_response_${RATE_HIGH}" \
  --duration ${DURATION_LONG} \
  --mode sync \
  --upload_url http://${PROVIDED_IP}:${PROVIDED_PORT}/


echo "[INFO] Docker Swarm tests done. Results saved in ./${RESULTS_DIR}/"


echo "[INFO] Cleaning up Swarm service..."
docker service rm ${SERVICE_NAME}

echo "[INFO] Leaving Docker Swarm..."
docker swarm leave --force

echo "[INFO] Docker Swarm test complete and cleaned up."
  