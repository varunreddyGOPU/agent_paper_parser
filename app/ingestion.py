import os
import requests
import fitz
import sqlite3
import logging
from app.database import DB_PATH
from app.embeddings import add_to_index

logger = logging.getLogger(__name__)

os.makedirs("downloads", exist_ok=True)


def download_pdf(url: str, filename: str) -> str:
    path = os.path.join("downloads", filename)
    try:
        r = requests.get(url, timeout=30)
        r.raise_for_status()
        with open(path, "wb") as f:
            f.write(r.content)
        return path
    except Exception:
        logger.exception("Failed to download %s", url)
        raise


def parse_pdf(path: str) -> str:
    text = ""
    try:
        doc = fitz.open(path)
        for page in doc:
            text += page.get_text("text") + "\n"
    except Exception:
        logger.exception("Failed to parse PDF %s", path)
        raise
    return text


def ingest_example():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    sample_url = "https://arxiv.org/pdf/1706.03762.pdf"
    try:
        path = download_pdf(sample_url, "attention_is_all_you_need.pdf")
        text = parse_pdf(path)
    except Exception:
        logger.exception("Skipping ingestion due to download/parse error")
        conn.close()
        return

    try:
        cur.execute("INSERT INTO papers (title, url, path, abstract) VALUES (?,?,?,?)",
                    ("Attention Is All You Need", sample_url, path, text[:500]))
        paper_id = cur.lastrowid
        conn.commit()
    except Exception:
        logger.exception("Failed to insert paper into DB")
        conn.rollback()
        conn.close()
        return
    conn.close()

    try:
        add_to_index(paper_id, text)
    except Exception:
        logger.exception("Failed to add paper to embeddings/index")