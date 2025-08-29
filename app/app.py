from flask import Flask, jsonify
import time

app = Flask(__name__)

@app.route("/")
def hello():
    return jsonify({
        "message": "Hello from Flask service! Checking",
        "timestamp": time.time()
    })

@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
