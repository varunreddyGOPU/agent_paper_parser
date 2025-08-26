#!/bin/bash
set -e

# Setup script for Agent Paper Parser
echo "🚀 Setting up Agent Paper Parser..."

# Check Python version
PYTHON_VERSION=$(python3 --version | grep -oE '[0-9]+\.[0-9]+')
if [[ $(echo "$PYTHON_VERSION >= 3.9" | bc -l) -eq 0 ]]; then
    echo "❌ Python 3.9+ required. Found: $PYTHON_VERSION"
    exit 1
fi
echo "✓ Python $PYTHON_VERSION detected"

# Create virtual environment
if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate
echo "✓ Virtual environment activated"

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt
pip install PyMuPDF  # Missing dependency

# Create data directories
echo "📁 Creating data directories..."
mkdir -p data downloads

# Initialize database
echo "🗃️ Initializing database..."
python run_init_db.py

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️ Creating default .env file..."
    cat > .env << EOF
# Environment configuration
HOST=127.0.0.1
PORT=8000

# Database
DB_PATH=./data/papers.db

# FAISS Index
INDEX_PATH=./data/faiss.index
METADATA_PATH=./data/metadata.json

# Default provider
PROVIDER=local
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2

# Set to 1 to run ingestion on startup
INGEST_ON_STARTUP=0

# OpenAI (uncomment and set if using OpenAI)
# OPENAI_API_KEY=your_openai_api_key_here
# LLM_MODEL=gpt-4o-mini

# Google Gemini (uncomment and set if using Gemini)
# GOOGLE_API_KEY=your_google_api_key_here
# LLM_MODEL=gemini-1.5-flash

# Langfuse (optional observability)
# LANGFUSE_PUBLIC_KEY=
# LANGFUSE_SECRET_KEY=
# LANGFUSE_HOST=
EOF
    echo "✓ Default .env file created"
else
    echo "✓ .env file already exists"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Edit .env file to configure your LLM provider (OpenAI/Gemini)"
echo "2. Run './scripts/start.sh' to start the server"
echo "3. Visit http://localhost:8000/docs for API documentation"
echo "4. Run './scripts/ingest.sh' to add sample papers"
echo ""
echo "📚 Available scripts:"
echo "  ./scripts/start.sh    - Start the development server"
echo "  ./scripts/ingest.sh   - Run PDF ingestion"
echo "  ./scripts/test.sh     - Run tests and health checks"
echo "  ./scripts/docker.sh   - Build and run with Docker"