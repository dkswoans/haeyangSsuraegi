import os
import sqlite3
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

DB_PATH = "data.db"
IMAGE_DIR = "images"


class Photo(BaseModel):
    id: int
    image_url: str
    received_at: str
    x: Optional[float] = None
    y: Optional[float] = None


app = FastAPI(title="Marine Cleaner Server")

os.makedirs(IMAGE_DIR, exist_ok=True)
app.mount("/media", StaticFiles(directory=IMAGE_DIR), name="media")

conn = sqlite3.connect(DB_PATH, check_same_thread=False)
cur = conn.cursor()
cur.execute(
    """
    CREATE TABLE IF NOT EXISTS photos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      filename TEXT NOT NULL,
      received_at TEXT NOT NULL,
      x REAL,
      y REAL
    )
    """
)
conn.commit()


@app.post("/upload", response_model=Photo)
async def upload(
    image: UploadFile = File(...),
    x: Optional[float] = Form(None),
    y: Optional[float] = Form(None),
):
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_%f")
    filename = f"{ts}.jpg"
    path = os.path.join(IMAGE_DIR, filename)

    content = await image.read()
    with open(path, "wb") as f:
        f.write(content)

    received_at = datetime.now(timezone.utc).isoformat()

    cur.execute(
        "INSERT INTO photos (filename, received_at, x, y) VALUES (?, ?, ?, ?)",
        (filename, received_at, x, y),
    )
    conn.commit()
    photo_id = cur.lastrowid

    return Photo(
        id=photo_id,
        image_url=f"/media/{filename}",
        received_at=received_at,
        x=x,
        y=y,
    )


@app.get("/photos", response_model=List[Photo])
def photos(
    after: Optional[str] = Query(None, description="ISO8601 timestamp; returns items received after this time"),
    limit: int = Query(50, ge=1, le=200),
):
    if after:
        try:
            _ = datetime.fromisoformat(after)
            cur.execute(
                """
                SELECT id, filename, received_at, x, y
                FROM photos
                WHERE received_at > ?
                ORDER BY id DESC
                LIMIT ?
                """,
                (after, limit),
            )
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid 'after' format; use ISO8601.")
    else:
        cur.execute(
            """
            SELECT id, filename, received_at, x, y
            FROM photos
            ORDER BY id DESC
            LIMIT ?
            """,
            (limit,),
        )

    rows = cur.fetchall()
    return [
        Photo(
            id=r[0],
            image_url=f"/media/{r[1]}",
            received_at=r[2],
            x=r[3],
            y=r[4],
        )
        for r in rows
    ]


@app.get("/photos/{photo_id}", response_model=Photo)
def photo_detail(photo_id: int):
    cur.execute(
        "SELECT id, filename, received_at, x, y FROM photos WHERE id = ?",
        (photo_id,),
    )
    row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Photo not found")

    return Photo(
        id=row[0],
        image_url=f"/media/{row[1]}",
        received_at=row[2],
        x=row[3],
        y=row[4],
    )
