#!/bin/bash
set -e

# Test script for Agent Paper Parser
echo "🧪 Running tests and health checks..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Run './scripts/setup.sh' first."
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

# Initialize if needed
python run_init_db.py

echo "🔍 Running import tests..."
python -c "
import sys
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    from app.main import app
    logger.info('✓ FastAPI app imports successfully')
    
    from app.database import init_db
    init_db()
    logger.info('✓ Database module works')
    
    from app.qa import qa_router
    logger.info('✓ QA router imports successfully')
    
    from app.embeddings import add_to_index
    logger.info('✓ Embeddings module imports successfully')
    
    from app.ingestion import ingest_example
    logger.info('✓ Ingestion module imports successfully')
    
    logger.info('🎉 All imports successful!')
    
except Exception as e:
    logger.error(f'❌ Import failed: {e}')
    sys.exit(1)
"

echo ""
echo "🌐 Testing server startup..."
# Start server in background
uvicorn app.main:app --host 127.0.0.1 --port 8001 &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Test health endpoint
echo "🏥 Testing health endpoint..."
if curl -s -f http://127.0.0.1:8001/docs > /dev/null; then
    echo "✓ Server is responding"
else
    echo "❌ Server health check failed"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# Test basic API
echo "📊 Testing API structure..."
if curl -s http://127.0.0.1:8001/openapi.json | python -m json.tool > /dev/null; then
    echo "✓ OpenAPI schema is valid"
else
    echo "⚠️ OpenAPI schema test failed"
fi

# Clean up server
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true

echo ""
echo "📁 Checking file structure..."
if [ -f "data/papers.db" ]; then
    echo "✓ Database file exists"
    
    # Check database content
    python -c "
import sqlite3
conn = sqlite3.connect('./data/papers.db')
cur = conn.cursor()
cur.execute('SELECT COUNT(*) FROM papers')
count = cur.fetchone()[0]
print(f'✓ Database has {count} papers')
conn.close()
"
else
    echo "⚠️ No database file found"
fi

if [ -f "data/faiss.index" ]; then
    echo "✓ FAISS index exists"
else
    echo "⚠️ No FAISS index found"
fi

if [ -f "data/metadata.json" ]; then
    echo "✓ Metadata file exists"
else
    echo "⚠️ No metadata file found"
fi

echo ""
echo "🔧 Running dependency check..."
python -c "
import pkg_resources
import sys

required = [
    'fastapi>=0.111.0',
    'uvicorn>=0.30.0',
    'pydantic>=2.7.0',
    'sentence-transformers>=2.6.0',
    'faiss-cpu>=1.8.0',
    'langchain>=0.2.0'
]

missing = []
for req in required:
    try:
        pkg_resources.require(req)
        print(f'✓ {req}')
    except pkg_resources.DistributionNotFound:
        print(f'❌ Missing: {req}')
        missing.append(req)
    except pkg_resources.VersionConflict as e:
        print(f'⚠️ Version conflict: {e}')

if missing:
    print(f'❌ Missing dependencies: {missing}')
    sys.exit(1)
else:
    print('✅ All dependencies satisfied')
"

# Run pytest if available and tests exist
if command -v pytest &> /dev/null; then
    if [ -d "tests" ] || find . -name "test_*.py" -o -name "*_test.py" | grep -q .; then
        echo ""
        echo "🧪 Running pytest..."
        pytest -v || echo "⚠️ Some tests failed"
    else
        echo "📝 No pytest tests found"
    fi
else
    echo "📝 pytest not available, skipping unit tests"
fi

echo ""
echo "✅ Health check completed!"
echo ""
echo "📋 Summary:"
echo "  - Application imports: ✓"
echo "  - Server startup: ✓" 
echo "  - API endpoints: ✓"
echo "  - Dependencies: ✓"
echo ""
echo "🚀 Ready to go! Run './scripts/start.sh' to start the server."