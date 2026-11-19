from flask import Flask, request, render_template, jsonify
import time

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/login", methods=["POST"])
def login():
    # Stub — accepts any credentials
    time.sleep(0.1)  # simulate work; makes it easy to overwhelm under load
    return jsonify({"status": "error", "message": "Service unavailable — high traffic. Please try again later."})


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
