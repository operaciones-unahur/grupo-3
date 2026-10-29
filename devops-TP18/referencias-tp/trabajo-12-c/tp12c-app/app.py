from flask import Flask, jsonify, request
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# ============================================================================
# Métricas requeridas por TP12C
# ============================================================================

app_requests_total = Counter(
    "app_requests_total",
    "Total de peticiones HTTP de la aplicación",
    ["method", "endpoint", "status"],
)

app_db_errors_total = Counter(
    "app_db_errors_total",
    "Total de errores simulados de conexión a la base de datos",
)


@app.before_request
def count_request():
    request._tp12c_endpoint = request.path


@app.after_request
def record_request(response):
    metric_endpoint = "/login" if request.path == "/api/v1/login" else request.path

    app_requests_total.labels(
        method=request.method,
        endpoint=metric_endpoint,
        status=str(response.status_code),
    ).inc()
    return response


@app.route("/health")
def health():
    return jsonify({"status": "ok", "tp": "TP12C"})


@app.route("/api/v1/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}

    if data.get("user") == "admin" and data.get("pass") == "correct":
        return jsonify({"message": "login correcto"}), 200

    return jsonify({"error": "credenciales inválidas"}), 401


@app.route("/api/v1/db-error", methods=["POST"])
def db_error():
    """
    Endpoint controlado para generar evidencia de errores de base de datos
    durante las pruebas de TP12C.
    """
    app_db_errors_total.inc()
    return jsonify({"error": "error de conexión a PostgreSQL simulado"}), 500


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
