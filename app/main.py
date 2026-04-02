import logging
import os
from datetime import datetime

from flask import Flask, jsonify, request


api = Flask(__name__)

RUNTIME_LOG_DIR = "/app/logs"
RUNTIME_LOG_PATH = os.path.join(RUNTIME_LOG_DIR, "app.log")

configured_verbosity = os.environ.get("VERBOSITY_LEVEL", "INFO").upper()
configured_port = int(os.environ.get("SERVICE_PORT", "5000"))
landing_message = os.environ.get("LANDING_MESSAGE", "Welcome to the custom app")

logging.basicConfig(
    level=getattr(logging, configured_verbosity, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(message)s",
)
runtime_logger = logging.getLogger("event-journal-api")

os.makedirs(RUNTIME_LOG_DIR, exist_ok=True)


def append_record(message_text):
    record_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(RUNTIME_LOG_PATH, "a", encoding="utf-8") as log_stream:
        log_stream.write(f"[{record_timestamp}] {message_text}\n")


def read_record_book():
    if not os.path.exists(RUNTIME_LOG_PATH):
        return ""
    with open(RUNTIME_LOG_PATH, "r", encoding="utf-8") as log_stream:
        return log_stream.read()


@api.route("/")
def landing_page():
    runtime_logger.info("GET /")
    return landing_message


@api.route("/status")
def heartbeat():
    runtime_logger.info("GET /status")
    return jsonify({"status": "ok"})


@api.route("/log", methods=["POST"])
def capture_message():
    payload = request.get_json(force=True)
    message_text = payload.get("message", "")
    append_record(message_text)
    runtime_logger.info("POST /log recorded payload: %s", message_text)
    return jsonify({"status": "logged", "message": message_text})


@api.route("/logs")
def export_records():
    runtime_logger.info("GET /logs")
    return read_record_book()


if __name__ == "__main__":
    runtime_logger.info("Starting event journal API on port %d", configured_port)
    api.run(host="0.0.0.0", port=configured_port)
