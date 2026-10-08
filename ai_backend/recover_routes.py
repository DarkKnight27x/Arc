"""FastAPI router for the temporary Recover API.

Mount this on the friend's coach when that app exists:

    from recover_routes import router as recover_router
    app.include_router(recover_router)

Until then, run recover_server.py. Same paths, same file store, same rule:
Arc records. It does not diagnose.
"""

from __future__ import annotations

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from recover_server import DISCLAIMER, MUSCLES, PHYSIOS, load, record_report, reply_for, save, now
import uuid

router = APIRouter(prefix="/recover", tags=["recover"])


class PhotoIn(BaseModel):
    filename: str
    mime_type: str | None = None
    byte_size: int = 0


class ReportIn(BaseModel):
    user_id: str = "saarthak"
    body_region: str | None = None
    muscle: str | None = None
    description: str | None = None
    note: str | None = None
    photo: PhotoIn | None = None


class MessageIn(BaseModel):
    user_id: str = "saarthak"
    message: str = Field(min_length=1)
    body_region: str | None = None
    photo: PhotoIn | None = None


class BookingIn(BaseModel):
    user_id: str = "saarthak"
    provider_id: str
    note: str = ""


@router.get("")
def snapshot(user_id: str = "saarthak") -> dict:
    data = load()
    return {
        "muscles": MUSCLES,
        "reports": [row for row in data["reports"] if row["user_id"] == user_id],
        "physios": PHYSIOS,
        "diagnoses": False,
        "disclaimer": DISCLAIMER,
    }


@router.get("/muscles")
def muscles() -> dict:
    return {"muscles": MUSCLES}


@router.get("/reports")
def reports(user_id: str = "saarthak") -> dict:
    data = load()
    return {
        "reports": [row for row in data["reports"] if row["user_id"] == user_id],
        "diagnoses": False,
        "disclaimer": DISCLAIMER,
    }


@router.post("/reports", status_code=201)
def create_report(body: ReportIn) -> dict:
    status, payload = record_report(body.model_dump())
    if status != 201:
        raise HTTPException(status, payload)
    return payload


@router.get("/physios")
def physios() -> dict:
    return {"physios": PHYSIOS, "city": "Thane"}


@router.post("/messages", status_code=201)
def message(body: MessageIn) -> dict:
    region = (body.body_region or "").strip() or None
    reply = reply_for(body.message, region)
    report = None
    resolved = region
    if resolved is None:
        from recover_server import find_muscle

        resolved = find_muscle(body.message)
    if resolved:
        status, payload = record_report(
            {
                "user_id": body.user_id,
                "body_region": resolved,
                "description": body.message,
                "photo": body.photo.model_dump() if body.photo else None,
            }
        )
        if status == 201:
            report = payload["report"]
    created = now()
    data = load()
    data["messages"].append(
        {
            "id": str(uuid.uuid4()),
            "user_id": body.user_id,
            "role": "user",
            "message": body.message,
            "body_region": resolved,
            "created_at": created,
        }
    )
    data["messages"].append(
        {
            "id": str(uuid.uuid4()),
            "user_id": body.user_id,
            "role": "arc",
            "message": reply,
            "body_region": resolved,
            "created_at": now(),
            "diagnoses": False,
        }
    )
    save(data)
    return {"reply": reply, "report": report, "diagnoses": False, "disclaimer": DISCLAIMER}


@router.post("/bookings", status_code=201)
def book(body: BookingIn) -> dict:
    provider = next((row for row in PHYSIOS if row["id"] == body.provider_id), None)
    if provider is None:
        raise HTTPException(404, {"error": "Physio not in the temporary list."})
    booking = {
        "id": str(uuid.uuid4()),
        "user_id": body.user_id,
        "provider_id": body.provider_id,
        "provider_name": provider["display_name"],
        "service_type": "physiotherapy",
        "status": "requested",
        "note": body.note.strip(),
        "created_at": now(),
    }
    data = load()
    data["bookings"].insert(0, booking)
    save(data)
    return {"booking": booking, "diagnoses": False, "disclaimer": DISCLAIMER}
