import hashlib
import os

from flask import Flask, request, render_template, jsonify

app = Flask(__name__)

# How much CPU each login burns, as a real password-hash (PBKDF2). This is the
# knob that makes the app buckle under load: with the container capped at a
# fraction of a core, a handful of concurrent logins exhaust the CPU budget and
# everything queues. Raise it to fall over sooner, lower it to survive longer.
HASH_ITERATIONS = int(os.environ.get("HASH_ITERATIONS", "150000"))


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    username = data.get("username") or "player"
    password = (data.get("password") or "").encode()
    # Verify credentials by deriving a key — genuine CPU-bound work on every
    # request (a normal login would hash the password too). Not a fake sleep:
    # this actually consumes the container's limited CPU.
    hashlib.pbkdf2_hmac("sha256", password, b"social-club-salt", HASH_ITERATIONS)
    return jsonify({"status": "ok", "message": f"Welcome back, {username}. You're signed in."})


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
