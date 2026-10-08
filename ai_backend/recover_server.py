"""Temporary Recover API.

Arc records what the user reports. It does not diagnose, grade, or prescribe.
File-backed so the Recover page can run before Supabase auth and storage are live.

Run from the Flutter project root (env file sits next to ai_backend, not inside it):

    python ai_backend/recover_server.py

Default: http://127.0.0.1:8787
"""

from __future__ import annotations

import json
import mimetypes
import re
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent
STORE_PATH = ROOT / "data" / "recover_store.json"
HOST = "0.0.0.0"
PORT = 8787

MUSCLES = [
    "Chest",
    "Shoulders",
    "Biceps",
    "Triceps",
    "Forearm",
    "Abs",
    "Upper back",
    "Lower back",
    "Glutes",
    "Quadriceps",
    "Hamstring",
    "Calves",
]

PHYSIOS = [
    {
        "id": "physio_motion_lab",
        "display_name": "Motion Lab Physio",
        "city": "Thane West",
        "distance_km": 1.2,
        "specialties": ["Sports", "shoulder"],
        "rating": 4.6,
        "session_price": 900,
        "currency": "INR",
        "image_url": "https://images.unsplash.com/photo-1519823551278-64ac92734fb1?auto=format&fit=crop&w=800&q=80",
    },
    {
        "id": "physio_restore",
        "display_name": "Restore Clinic",
        "city": "Naupada",
        "distance_km": 2.1,
        "specialties": ["Post-op", "strength"],
        "rating": 4.4,
        "session_price": 800,
        "currency": "INR",
        "image_url": "https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=800&q=80",
    },
    {
        "id": "physio_hiranandani",
        "display_name": "Hiranandani Physio",
        "city": "Powai",
        "distance_km": 6.4,
        "specialties": ["Knee", "spine"],
        "rating": 4.7,
        "session_price": 1100,
        "currency": "INR",
        "image_url": "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=800&q=80",
    },
    {
        "id": "physio_bandra",
        "display_name": "Bandra Sports PT",
        "city": "Bandra West",
        "distance_km": 18.0,
        "specialties": ["Lifters", "return to gym"],
        "rating": 4.5,
        "session_price": 1200,
        "currency": "INR",
        "image_url": "https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=800&q=80",
    },
]

DISCLAIMER = "Recorded only. Arc does not diagnose."


def now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def empty_store() -> dict:
    return {"reports": [], "documents": [], "messages": [], "bookings": []}


def load() -> dict:
    if not STORE_PATH.exists():
        return empty_store()
    try:
        data = json.loads(STORE_PATH.read_text())
    except json.JSONDecodeError:
        return empty_store()
    for key in empty_store():
        data.setdefault(key, [])
    return data


def save(data: dict) -> None:
    STORE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STORE_PATH.write_text(json.dumps(data, indent=2))


def find_muscle(text: str) -> str | None:
    lowered = text.lower()
    for muscle in MUSCLES:
        if muscle.lower() in lowered:
            return muscle
    aliases = {
        "shoulder": "Shoulders",
        "pec": "Chest",
        "pecs": "Chest",
        "back": "Upper back",
        "quad": "Quadriceps",
        "quads": "Quadriceps",
        "ham": "Hamstring",
        "hams": "Hamstring",
        "glute": "Glutes",
        "calf": "Calves",
        "bicep": "Biceps",
        "tricep": "Triceps",
    }
    for alias, muscle in aliases.items():
        if re.search(rf"\b{alias}\b", lowered):
            return muscle
    return None


def record_report(body: dict) -> tuple[int, dict]:
    region = (body.get("body_region") or body.get("muscle") or "").strip()
    description = (body.get("description") or body.get("note") or "").strip()
    if not region:
        region = find_muscle(description) or ""
    if not region:
        return 400, {"error": "Choose a muscle before Arc can record this.", "diagnoses": False}
    if region not in MUSCLES:
        return 400, {"error": "Unknown muscle. Pick one from the Recover list.", "muscles": MUSCLES}
    if not description:
        description = f"Reported {region}."
    user_id = (body.get("user_id") or "saarthak").strip() or "saarthak"
    photo = body.get("photo") if isinstance(body.get("photo"), dict) else None
    created = now()
    report = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "body_region": region,
        "description": description,
        "status": "active",
        "created_at": created,
        "updated_at": created,
        "disclaimer": DISCLAIMER,
    }
    data = load()
    data["reports"].insert(0, report)
    document = None
    if photo and photo.get("filename"):
        filename = str(photo["filename"])
        document = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "rehab_case_id": report["id"],
            "document_type": "report",
            "storage_path": f"tmp/{user_id}/{report['id']}/{filename}",
            "original_filename": filename,
            "mime_type": photo.get("mime_type") or mimetypes.guess_type(filename)[0] or "image/jpeg",
            "byte_size": int(photo.get("byte_size") or 0),
            "status": "uploaded",
            "uploaded_at": created,
        }
        data["documents"].insert(0, document)
        report["document_id"] = document["id"]
    save(data)
    return 201, {"report": report, "document": document, "diagnoses": False, "disclaimer": DISCLAIMER}


def reply_for(message: str, region: str | None) -> str:
    muscle = region or find_muscle(message)
    if not muscle:
        return "Which muscle? Pick one, then Arc will record the note. Arc does not diagnose."
    return (
        f"Recorded: {muscle}. "
        "Arc kept your note and will not diagnose it. "
        "A physio near Thane can look at it if you want a person to."
    )


class Handler(BaseHTTPRequestHandler):
    server_version = "ArcRecoverTemp/0.1"

    def log_message(self, fmt: str, *args) -> None:
        print(f"[recover] {self.address_string()} {fmt % args}")

    def _send(self, status: int, payload: dict) -> None:
        raw = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()
        self.wfile.write(raw)

    def do_OPTIONS(self) -> None:  # noqa: N802
        self._send(204, {})

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        path = parsed.path.rstrip("/") or "/"
        user_id = (query.get("user_id") or ["saarthak"])[0]
        data = load()

        if path in ("/", "/health"):
            self._send(200, {"ok": True, "service": "recover-temp", "diagnoses": False})
            return
        if path == "/recover":
            reports = [row for row in data["reports"] if row["user_id"] == user_id]
            self._send(
                200,
                {
                    "muscles": MUSCLES,
                    "reports": reports,
                    "physios": PHYSIOS,
                    "diagnoses": False,
                    "disclaimer": DISCLAIMER,
                },
            )
            return
        if path == "/recover/muscles":
            self._send(200, {"muscles": MUSCLES})
            return
        if path == "/recover/reports":
            reports = [row for row in data["reports"] if row["user_id"] == user_id]
            self._send(200, {"reports": reports, "diagnoses": False, "disclaimer": DISCLAIMER})
            return
        if path == "/recover/physios":
            self._send(200, {"physios": PHYSIOS, "city": "Thane"})
            return
        if path == "/recover/messages":
            messages = [row for row in data["messages"] if row["user_id"] == user_id]
            self._send(200, {"messages": messages, "diagnoses": False})
            return
        self._send(404, {"error": "Not found"})

    def do_POST(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw.decode() or "{}")
        except json.JSONDecodeError:
            self._send(400, {"error": "Body must be JSON."})
            return
        if not isinstance(body, dict):
            self._send(400, {"error": "Body must be a JSON object."})
            return

        if path == "/recover/reports":
            status, payload = record_report(body)
            self._send(status, payload)
            return
        if path == "/recover/messages":
            message = (body.get("message") or "").strip()
            if not message:
                self._send(400, {"error": "Message is empty."})
                return
            user_id = (body.get("user_id") or "saarthak").strip() or "saarthak"
            region = (body.get("body_region") or "").strip() or find_muscle(message)
            created = now()
            reply = reply_for(message, region)
            report = None
            if region:
                status, payload = record_report(
                    {
                        "user_id": user_id,
                        "body_region": region,
                        "description": message,
                        "photo": body.get("photo"),
                    }
                )
                if status == 201:
                    report = payload["report"]
            data = load()
            data["messages"].append(
                {
                    "id": str(uuid.uuid4()),
                    "user_id": user_id,
                    "role": "user",
                    "message": message,
                    "body_region": region,
                    "created_at": created,
                }
            )
            data["messages"].append(
                {
                    "id": str(uuid.uuid4()),
                    "user_id": user_id,
                    "role": "arc",
                    "message": reply,
                    "body_region": region,
                    "created_at": now(),
                    "diagnoses": False,
                }
            )
            save(data)
            self._send(201, {"reply": reply, "report": report, "diagnoses": False, "disclaimer": DISCLAIMER})
            return
        if path == "/recover/bookings":
            provider_id = (body.get("provider_id") or "").strip()
            provider = next((row for row in PHYSIOS if row["id"] == provider_id), None)
            if provider is None:
                self._send(404, {"error": "Physio not in the temporary list."})
                return
            booking = {
                "id": str(uuid.uuid4()),
                "user_id": (body.get("user_id") or "saarthak").strip() or "saarthak",
                "provider_id": provider_id,
                "provider_name": provider["display_name"],
                "service_type": "physiotherapy",
                "status": "requested",
                "note": (body.get("note") or "").strip(),
                "created_at": now(),
            }
            data = load()
            data["bookings"].insert(0, booking)
            save(data)
            self._send(201, {"booking": booking, "diagnoses": False, "disclaimer": DISCLAIMER})
            return
        self._send(404, {"error": "Not found"})


def main() -> None:
    STORE_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        save(empty_store())
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Arc Recover temporary backend on http://{HOST}:{PORT}")
    print("Records only. Does not diagnose.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
