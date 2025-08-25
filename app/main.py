from fastapi import FastAPI
import os
import logging

from app.qa import qa_router
from app.database import init_db
from app.ingestion import ingest_example

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()
app.include_router(qa_router)


if __name__ == "__main__":
    init_db()
    # Only ingest on startup when explicitly enabled
    if os.getenv("INGEST_ON_STARTUP", "0") == "1":
        logger.info("INGEST_ON_STARTUP=1, running ingest_example()")
        try:
            ingest_example()
        except Exception:
            logger.exception("ingest_example failed during startup")
    else:
        logger.info("Skipping ingest on startup (set INGEST_ON_STARTUP=1 to enable)")

    import uvicorn
    uvicorn.run(app, host=os.getenv("HOST", "127.0.0.1"), port=int(os.getenv("PORT", "8000")))