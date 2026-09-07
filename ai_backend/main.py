from fastapi import FastAPI

app = FastAPI(title="Arc AI Backend")


@app.get("/health")
def health():
    return {"status": "ok"}