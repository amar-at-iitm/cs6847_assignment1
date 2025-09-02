
# Container Orchestration Load Testing

This section provides **automated scripts to test a Flask application** deployed using two container orchestration platforms: **Docker Swarm** and **Kubernetes (via Minikube)**.



## Prerequisites

Ensure you are working in **linux environment** and have the following installed:

- Docker
- Docker Swarm (`docker swarm init` should work)
- Minikube
- kubectl
- Python 3 (with dependencies for `client/client.py`)


## Scripts Overview

### `run_all_tests.sh`

This script does the following:

1. **Docker Swarm Test**
   - Builds the Docker image.
   - Initializes Docker Swarm (if not already running).
   - Deploys a Swarm service with 3 replicas.
   - Sends a test HTTP request to the service.
   - Cleans up the service and leaves the Swarm.

2. **Kubernetes Test (Minikube)**
   - Starts Minikube.
   - Builds the Docker image inside Minikube.
   - Applies Kubernetes manifests (`deployment.yaml`, `service.yaml`, etc.).
   - Waits for the service to become available.
   - Runs two load tests using `client/client.py`:
     - Low rate: 10 requests/sec for 5 seconds.
     - High rate: 10,000 requests/sec for 2 seconds.
   - Saves results to `./results/`.
   - Cleans up Kubernetes resources.
   - Stops Minikube.



### `run_swarm_tests.sh`

This script does the following:

   - Builds the Docker image.
   - Initializes Docker Swarm (if not already running).
   - Deploys a Swarm service with 3 replicas.
   - Sends a test HTTP request to the service.
   - Cleans up the service and leaves the Swarm.





### `run_k8s_tests.sh`

This script does the following:

   - Starts Minikube.
   - Builds the Docker image inside Minikube.
   - Applies Kubernetes manifests (`deployment.yaml`, `service.yaml`, etc.).
   - Waits for the service to become available.
   - Runs two load tests using `client/client.py`:
     - Low rate: 10 requests/sec for 5 seconds.
     - High rate: 10,000 requests/sec for 2 seconds.
   - Saves results to `./results/`.
   - Cleans up Kubernetes resources.
   - Stops Minikube.

---



## Usage

### Make the script executable from the root of the project:

```bash
chmod +x run_all_tests.sh
# or
chmod +x run_swarm_test.sh
# or 
chmod +x run_k8s_test.sh

```

### Run the full test suite:

```bash
./run_all_tests.sh
# or 
./run_swarm_test.sh
# or 
./run_k8s_test.sh

```

## Output

Test results will be saved to the `results/` directory:

* `results/docker_response_10`
* `results/docker_response_10000`
* `results/kubernetes_response_10`
* `results/kubernetes_response_10000`

These files will contain latency and throughput data from the test client.

---

## Cleanup

The script automatically:

* Removes the Docker Swarm service and leaves the swarm.
* Deletes all Kubernetes resources applied.
* Stops Minikube after the tests are done.

No manual cleanup required.

---



## Notes

* The Kubernetes part uses `minikube service flask-service --url` to expose the service; this assumes your Kubernetes service is named `flask-service`.
* `client.py` must support arguments: `--target`, `--rate`, `--output`, and `--duration`.
* If Swarm is already active, the script will skip re-initializing it.

