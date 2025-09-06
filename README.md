# CS6847(Cloud Computing) Assignment 1 – Docker Swarm & Kubernetes Deployment with Client Testing
## Assignment Overview
This assignment implements a simple **Flask web service** that runs both on **Docker Swarm** and **Kubernetes**.

A Python client benchmarks the service at **10 requests/sec** and **10,000 requests/sec**, storing results for evaluation.

## Requirements
- Docker & Docker Swarm
- Minikube (for Kubernetes)
- Python 3.11+
- Virtual environment (recommended)



## Folder Structure
```
assignment1/

│── .dockerignore              
│── .gitignore                  
│── run_swarm_test.sh 
│── run_k8s_test.sh
│── run_all_tests.sh
│── README.md                 
│
├── app/                      # Application code (the web service)
│   ├── requirements.txt                 
│   ├── app.py                 # Flask service
│   ├── Dockerfile             # Dockerfile for the service
│   └── __init__.py            # (empty, just keeps it tidy as a package)
│
│
├── kubernetes/               # Kubernetes deployment files
│   ├── deployment.yaml        # Deployment with min 3 replicas
│   ├── hpa.yaml               # Horizontal Pod Autoscaler (min 3, max 10)
│   └── service.yaml           # Service to expose Flask app
│
├── client/                   # Client code to test service
│   ├── client.py              # Sends requests, measures response time
│   └── utils.py               # helper functions for clients.py
│
└── results/                  
    ├── docker_response_10
    ├── docker_response_10000
    ├── kubernetes_response_10
    └── kubernetes_response_10000

```

## Architecture & Components
- **app/**: Flask web service (`app.py`), containerized via `Dockerfile`.
- **client/**: Load-testing client (`client.py`) and helpers (`utils.py`).
- **kubernetes/**: Kubernetes manifests for deployment, service, and autoscaling (3–10 replicas).
- **results/**: Stores output from client runs.

## Service Endpoints

* `GET /` → Hello world message
* `GET /info` → Runtime info (pod/container name, namespace, CPU, memory usage)

Example response from `/info` inside Kubernetes:

```json
{
  "pod_name": "flask-deployment-6fbdcc7f8d-rj7x2",
  "namespace": "default",
  "hostname": "flask-deployment-6fbdcc7f8d-rj7x2",
  "cpu_percent": 1.2,
  "memory_usage_mb": 28.5
}
```


## Clone repo
```bash
git clone https://github.com/amar-at-iitm/cs6847_assignment1
cd cs6847_assignment1
```

## Install Dependencies
```bash
pip install -r requirements.txt
```

** [Automated Testing](https://github.com/amar-at-iitm/cs6847_assignment1/blob/main/automate_test.md)   (If you are working on linux environment, then you can perform all the test automatically.)



## Running with Docker Swarm

1. Build the Docker image:

   ```bash
   docker build -t flask-app:latest app/
   ```

2. Initialize swarm (if not already):

   ```bash
   docker swarm init
   ```

3. Deploy service with 3 replicas:

   ```bash
   docker service create --name flask-service --replicas 3 -p 5000:5000 flask-app:latest
   ```

4. Verify:

   ```bash
   docker service ls
   curl http://127.0.0.1:5000/info
   ```

### Running the Client

#### 1. Docker benchmark @ 10 requests/sec

```bash
python client/client.py \
  --target http://127.0.0.1:5000 \
  --rate 10 \
  --duration 5 \
  --output results/docker_response_10 \
  --mode sync
  --upload_url http://< provided_IP >:port/
```

#### 2. Docker benchmark @ 10,000 requests/sec

```bash
python client/client.py \
  --target http://127.0.0.1:5000 \
  --rate 10000 \
  --duration 2 \
  --output results/docker_response_10000 \
  --mode async
  --upload_url http://< provided_IP >:port/
```

  - Adjust `--rate` and `--output` as needed for experiments.
  - " http://< provided_IP >:port/ " use the required addressed to 


### Clean up
```bash
docker service rm flask-service
docker swarm leave --force
```

## Running with Kubernetes (Minikube)

1. Start Minikube:

   ```bash
   minikube start
   ```

2. Set Docker env to use Minikube's Docker daemon

   ```bash
   eval $(minikube docker-env)
   ```

3. Build the Docker image inside minikube

   ```bash
   docker build -t flask-app:latest app/
   ```

4. Deploy:

   ```bash
   kubectl apply -f kubernetes/
   ```

5. Verify pods & service:

   ```bash
   kubectl get pods
   kubectl get svc
   kubectl get hpa
   ```

6. Get Minicube ip and port
    ```bash
    minikube service flask-service --url
    ```
    - From the output get `http://$(minikube ip):port`

7. Access the service:

   ```bash
   curl http://$(minikube ip):port/info
   ```


### Running the Client

#### 1. Kubernetes benchmark @ 10 requests/sec

```bash
python client/client.py \
  --target http://$(minikube ip):port \
  --rate 10 \
  --duration 5 \
  --output results/kubernetes_response_10 \
  --mode sync
  --upload_url http://< provided_IP >:port/
```

#### 2. Kubernetes benchmark @ 10,000 requests/sec
```bash
python client/client.py \
  --target http://$(minikube ip):port \
  --rate 10000 \
  --duration 2 \
  --output results/kubernetes_response_10000 \
  --mode async
  --upload_url http://< provided_IP >:port/
```
  - Adjust `--rate` and `--output` as needed for experiments.
  - " http://< provided_IP >:port/ " use the required addressed to 


### Clean up
```bash
kubectl delete -f kubernetes/
minikube stop
```


## Result Files

Four result files will be generated:

* `results/docker_response_10`
* `results/docker_response_10000`
* `results/kubernetes_response_10`
* `results/kubernetes_response_10000`

Each file contains per-request times followed by a **summary**:

```
0.002134
0.001995
...

=== Summary ===
Total requests: 50
Successful requests: 50
Failed requests: 0
Average response time: 0.002080 seconds
Median response time: 0.002100 seconds
Min response time: 0.001920 seconds
Max response time: 0.002310 seconds
```

## Conventions & Patterns
- All service endpoints are exposed on `/` (root) and listen on port 5000 (Docker) or as mapped by Kubernetes.
- Results are always written to the `results/` directory with descriptive filenames.
- Kubernetes uses autoscaling (see `hpa.yaml`), Swarm uses fixed replicas.
- No authentication or persistent storage is used; the service is stateless.

## Integration Points
- The client is decoupled and can target any HTTP endpoint.
- Docker and Kubernetes deployments are independent; **do not run both simultaneously** on the same port.
- All configuration is via YAML (Kubernetes) or CLI (Swarm).
