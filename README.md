# cs6847 Assignment 1 – Docker Swarm & Kubernetes Deployment with Client Testing
## Project Overview
This project demonstrates deploying a simple Flask web service using both Docker Swarm and Kubernetes, with a Python client for load testing. It is structured for reproducible experiments and benchmarking.

## Requirements
- Docker & Docker Swarm
- Minikube (for Kubernetes)
- Python 3.11+
- Virtual environment (recommended)



## Folder Structure
```
assignment1/

│── .dockerignore              # Ignore unnecessary files
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
│   ├── hpa.yaml               # Horizontal Pod Autoscaler (max 10)
│   └── service.yaml           # Service to expose Flask app
│
├── client/                   # Client code to test service
│   ├── client.py              # Sends requests, measures response time
│   └── utils.py               # (optional helper functions: avg calc, file writing)
│
└── results/                  # Output gets stored here
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


### clone repo
```bash
git clone https://github.com/amar-at-iitm/cs6847_assignment1
cd cs6847_assignment1
```

## Key Workflows
- **Build & Test Locally**:
  - Install Python dependencies: 
  ```bash
  pip install -r app/requirements.txt
  ```
  - Run Flask app locally: 
  ```bash
  python app/app.py
  ```

- **Docker Swarm**:
  - Build image: 
  ```bash
  docker build -t flask-app:latest app/
  ```
  - Init Swarm: 
  ```bash
  docker swarm init
  ```
  - Deploy: 
  ```bash
  docker service create --name flask-swarm --replicas 3 -p 5000:5000 flask-app:latest
  ```


- **Kubernetes (Minikube)**:
  - Start: 
  ```bash
  minikube start
  ```
  - Use Minikube Docker: 
  ```bash
  eval $(minikube docker-env)
  ```
  - Build image: 
  ```bash
  docker build -t flask-app:latest app/
  ```
  - Deploy: 
  ```bash
  kubectl apply -f kubernetes/
  ```
  - Get service URL: 
  ```bash
  minikube service flask-service --url
  ```
- **Client Testing**:
  - Example: 
    ```bash
    cd client
    ```

    ```bash
    python client.py --target http://<IP>:<PORT> --rate 10 --output ../results/docker_response_10
    python client.py --target http://<IP>:<PORT> --rate 10000 --output ../results/docker_response_10000
    ```

    ```bash
    python client.py --target http://<IP>:<PORT> --rate 10 --output ../results/kubernetes_response_10
    python client.py --target http://<IP>:<PORT> --rate 10000 --output ../results/kubernetes_response_10000
    ```


  - Adjust `--rate` and `--output` as needed for experiments.

## Conventions & Patterns
- All service endpoints are exposed on `/` (root) and listen on port 5000 (Docker) or as mapped by Kubernetes.
- Results are always written to the `results/` directory with descriptive filenames.
- Kubernetes uses autoscaling (see `hpa.yaml`), Swarm uses fixed replicas.
- No authentication or persistent storage is used; the service is stateless.

## Integration Points
- The client is decoupled and can target any HTTP endpoint.
- Docker and Kubernetes deployments are independent; do not run both simultaneously on the same port.
- All configuration is via YAML (Kubernetes) or CLI (Swarm).
