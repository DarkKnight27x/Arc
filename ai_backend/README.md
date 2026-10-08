# Temporary Recover backend

Arc records a reported muscle and note. It does not diagnose.

Run from the Flutter project root so the env file can sit next to `ai_backend/`:

```bash
python ai_backend/recover_server.py
```

Listens on `http://127.0.0.1:8787`. Store is `ai_backend/data/recover_store.json`.

| Method | Path | What it does |
| --- | --- | --- |
| GET | `/health` | Up, and `diagnoses: false` |
| GET | `/recover?user_id=saarthak` | Muscles, reports, physio seed |
| POST | `/recover/reports` | Save `{ body_region, description, photo? }` |
| GET | `/recover/reports` | Active reports for the demo user |
| GET | `/recover/physios` | Thane list used by the Physio sheet |
| POST | `/recover/messages` | Chat bar. Records only if a muscle is chosen or named |
| POST | `/recover/bookings` | Request a seeded physio |

Demo user is `saarthak`. Photo bytes are not stored; only filename and size, until the `medical-documents` bucket is live.

`recover_routes.py` is the same API as a FastAPI router for the friend's coach. Do not start both servers on 8787.
