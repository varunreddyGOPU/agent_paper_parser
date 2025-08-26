#!/bin/bash
set -e

# Start script for Agent Paper Parser
echo "🚀 Starting Agent Paper Parser..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Run './scripts/setup.sh' first."
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️ No .env file found. Creating default..."
    cp .env.example .env 2>/dev/null || echo "No .env.example found"
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set defaults
HOST=${HOST:-127.0.0.1}
PORT=${PORT:-8000}

# Initialize database if needed
if [ ! -f "data/papers.db" ]; then
    echo "🗃️ Initializing database..."
    python run_init_db.py
fi

# Run ingestion on startup if enabled
if [ "${INGEST_ON_STARTUP:-0}" = "1" ]; then
    echo "📚 Running ingestion on startup..."
    python -c "
from app.database import init_db
from app.ingestion import ingest_example
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    init_db()
    ingest_example()
    logger.info('✅ Ingestion completed')
except Exception as e:
    logger.error(f'❌ Ingestion failed: {e}')
" || echo "⚠️ Ingestion failed, continuing anyway..."
fi

echo "🌐 Starting server at http://$HOST:$PORT"
echo "📖 API docs will be available at http://$HOST:$PORT/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
uvicorn app.main:app --host "$HOST" --port "$PORT" --reload