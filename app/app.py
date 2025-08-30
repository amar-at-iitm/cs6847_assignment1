# app/app.py

from flask import Flask, jsonify
import os
import psutil
import socket

app = Flask(__name__)

@app.route("/")
def hello():
    return jsonify({"message": "Hello from Flask app running in Docker/Kubernetes!"})


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/info")
def info():
    # Pod info (if running inside Kubernetes)
    pod_name = os.getenv("POD_NAME", "unknown")
    namespace = os.getenv("POD_NAMESPACE", "unknown")

    # Host info
    hostname = socket.gethostname()

    # Resource usage
    process = psutil.Process(os.getpid())
    cpu_percent = psutil.cpu_percent(interval=0.1)
    mem_info = process.memory_info().rss / (1024 * 1024)  # MB

    return jsonify({
        "pod_name": pod_name,
        "namespace": namespace,
        "hostname": hostname,
        "cpu_percent": cpu_percent,
        "memory_usage_mb": mem_info
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
