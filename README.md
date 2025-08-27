# cs6847 Assignment 1 – Docker Swarm & Kubernetes Deployment with Client Testing

## Requirements
- Docker & Docker Swarm
- Minikube (for Kubernetes)
- Python 3.11+
- Virtual environment (recommended)



## Folder Structure
```
assignment1/

│── .dockerignore              # Ignore unnecessary files
│── README.md                 
│
├── app/                      # Application code (the web service)
│   ├── requirements.txt                 
│   ├── app.py                 # Flask service
│   ├── Dockerfile             # Dockerfile for the service
│   └── __init__.py            # (empty, just keeps it tidy as a package)
│
├── swarm/                    # Docker Swarm deployment files
│   └── swarm-deploy.sh        # Script to deploy service with 3 replicas
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


### clone repo
```bash
git clone https://github.com/amar-at-iitm/cs6847_assignment1
cd cs6847_assignment1
```

### Install dependencies:
```bash
pip install -r requirements.txt
```

### Start Minikube
```bash 
minikube start
```

### Setup Minikube’s local Docker environment
Build the image inside Minikube’s Docker daemon so your cluster can use it directly
```bash
eval $(minikube docker-env)
```

### Build Docker Image

```bash
cd app
docker build -t flask-app:latest .
```

**Check the image exists**
```bash
docker images | grep flask-app
```

### Initialize Docker Swarm
```bash
docker swarm init
```

### Run with Docker Swarm ( 3 Replicas)
```bash
docker service create --name flask-swarm --replicas 3 -p 5000:5000 flask-service:latest
```
**Check Service**
```bash
docker service ls
```


### Run with Kubernetes ( autoscaling 3-10 replicas )
**Deploy**
```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/hpa.yaml
```
**check status**
```bash
kubectl get pods
kubectl get svc
kubectl get hpa
```
### Run Client Test
Run the client to test Docker Swarm or Kubernetes services:
```bash
cd client
python client.py --target http://<IP>:<PORT> --rate 10 --output ../results/docker_response_10
python client.py --target http://<IP>:<PORT> --rate 10000 --output ../results/docker_response_10000
```
**Similarly for Kubernetes:**
```bash
python client.py --target http://<IP>:<PORT> --rate 10 --output ../results/kubernetes_response_10
python client.py --target http://<IP>:<PORT> --rate 10000 --output ../results/kubernetes_response_10000
```


### Output

- results/docker_response_10

- results/docker_response_10000

- results/kubernetes_response_10

- results/kubernetes_response_10000


### Look at services 
```bash
minikube service flask-service --url
```




### For client.py, Examples
**Test Docker Swarm (10 req/s):**
```bash 
python client.py --target http://<SWARM_IP>:5000 --rate 10 --output ../results/docker_response_10
```
**Test Docker Swarm (10,000 req/s):**
```bash
python client.py --target http://<SWARM_IP>:5000 --rate 10000 --output ../results/docker_response_10000
```
**Test Kubernetes (10 req/s):**
```bash
python client.py --target http://<K8S_IP>:30007 --rate 10 --output ../results/kubernetes_response_10
```
**Test Kubernetes (10,000 req/s):**
```bash
python client.py --target http://<K8S_IP>:30007 --rate 10000 --output ../results/kubernetes_response_10000
```
- Run it for a shorter duration with `--duration 2`(default is 5 sec).