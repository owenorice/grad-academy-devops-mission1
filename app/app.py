from flask import Flask, request, render_template, jsonify

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/login", methods=["POST"])
def login():
    # Accepts any credentials and "signs in". A normal, working endpoint — the
    # only load on this app comes from real external traffic (e.g. Locust).
    data = request.get_json(silent=True) or {}
    username = data.get("username") or "player"
    return jsonify({"status": "ok", "message": f"Welcome back, {username}. You're signed in."})


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
