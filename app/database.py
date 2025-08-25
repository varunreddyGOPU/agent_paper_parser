"""Small database utilities for the sample project.

Provides DB_PATH and an init_db() helper that creates the `papers` table
if it does not exist. This mirrors the schema used by
`create_sample_db.py` and lets `app/main.py` call `init_db()` safely.
"""
import sqlite3

DB_PATH = "papers.db"


def init_db() -> None:
    """Create the papers table if it doesn't already exist.

    This is intentionally lightweight so the project can run without
    external database setup.
    """
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS papers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            url TEXT,
            path TEXT,
            abstract TEXT
        )
    """)
    conn.commit()
    conn.close()
