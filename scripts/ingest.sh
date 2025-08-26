#!/bin/bash
set -e

# Ingestion script for Agent Paper Parser
echo "📚 Running PDF ingestion..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Run './scripts/setup.sh' first."
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

# Initialize database if needed
python run_init_db.py

# Parse command line arguments
REBUILD=false
PDF_URL=""
HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --rebuild)
            REBUILD=true
            shift
            ;;
        --pdf-url)
            PDF_URL="$2"
            shift 2
            ;;
        --help|-h)
            HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            HELP=true
            shift
            ;;
    esac
done

if [ "$HELP" = true ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --rebuild       Rebuild the FAISS index"
    echo "  --pdf-url URL   Ingest a specific PDF from URL"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                                    # Run sample ingestion"
    echo "  $0 --pdf-url https://arxiv.org/pdf/1706.03762.pdf   # Ingest specific PDF"
    echo "  $0 --rebuild                                          # Rebuild embeddings index"
    exit 0
fi

if [ "$REBUILD" = true ]; then
    echo "🔄 Rebuilding FAISS index..."
    python -c "
from app.embeddings import rebuild_index
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    rebuild_index()
    logger.info('✅ Index rebuilt successfully')
except Exception as e:
    logger.error(f'❌ Rebuild failed: {e}')
    raise
"
    exit 0
fi

if [ -n "$PDF_URL" ]; then
    echo "📄 Ingesting PDF from: $PDF_URL"
    python -c "
import sys
import logging
import os
from urllib.parse import urlparse
from app.ingestion import download_pdf, parse_pdf
from app.database import init_db
from app.embeddings import add_to_index
import sqlite3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

url = '$PDF_URL'
try:
    # Generate filename from URL
    parsed = urlparse(url)
    filename = os.path.basename(parsed.path) or 'document.pdf'
    if not filename.endswith('.pdf'):
        filename += '.pdf'
    
    logger.info(f'Downloading: {url}')
    path = download_pdf(url, filename)
    
    logger.info(f'Parsing: {path}')
    text = parse_pdf(path)
    
    # Store in database
    init_db()
    conn = sqlite3.connect('./data/papers.db')
    cur = conn.cursor()
    
    cur.execute('INSERT INTO papers (title, url, path, abstract) VALUES (?,?,?,?)',
               (filename, url, path, text[:500]))
    paper_id = cur.lastrowid
    conn.commit()
    conn.close()
    
    # Add to index
    add_to_index(paper_id, text)
    
    logger.info(f'✅ Successfully ingested: {filename}')
    
except Exception as e:
    logger.error(f'❌ Ingestion failed: {e}')
    sys.exit(1)
"
else
    echo "📚 Running sample ingestion..."
    python -c "
from app.database import init_db
from app.ingestion import ingest_example
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    init_db()
    ingest_example()
    logger.info('✅ Sample ingestion completed')
except Exception as e:
    logger.error(f'❌ Ingestion failed: {e}')
    raise
"
fi

echo "✅ Ingestion completed!"
echo ""
echo "📊 Database status:"
python -c "
import sqlite3
import os

if os.path.exists('./data/papers.db'):
    conn = sqlite3.connect('./data/papers.db')
    cur = conn.cursor()
    cur.execute('SELECT COUNT(*) FROM papers')
    count = cur.fetchone()[0]
    print(f'  Papers in database: {count}')
    conn.close()
else:
    print('  No database found')
"

if [ -f "data/faiss.index" ]; then
    INDEX_SIZE=$(du -h data/faiss.index | cut -f1)
    echo "  FAISS index size: $INDEX_SIZE"
fi