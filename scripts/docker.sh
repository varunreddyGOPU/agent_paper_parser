#!/bin/bash
set -e

# Docker script for Agent Paper Parser
echo "🐳 Docker operations for Agent Paper Parser..."

# Parse command line arguments
ACTION=""
HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        build)
            ACTION="build"
            shift
            ;;
        run)
            ACTION="run"
            shift
            ;;
        stop)
            ACTION="stop"
            shift
            ;;
        logs)
            ACTION="logs"
            shift
            ;;
        clean)
            ACTION="clean"
            shift
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

if [ "$HELP" = true ] || [ -z "$ACTION" ]; then
    echo "Usage: $0 <action>"
    echo ""
    echo "Actions:"
    echo "  build    Build the Docker image"
    echo "  run      Run the application with Docker Compose"
    echo "  stop     Stop the running containers"
    echo "  logs     Show container logs"
    echo "  clean    Clean up containers and images"
    echo "  --help   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build      # Build the Docker image"
    echo "  $0 run        # Start the application"
    echo "  $0 logs       # View logs"
    echo "  $0 stop       # Stop the application"
    exit 0
fi

case $ACTION in
    build)
        echo "🔨 Building Docker image..."
        docker build -t agent-paper-parser .
        echo "✅ Docker image built successfully!"
        ;;
    
    run)
        echo "🚀 Starting application with Docker Compose..."
        
        # Create data directories
        mkdir -p data downloads
        
        # Check if .env exists, create if not
        if [ ! -f ".env" ]; then
            echo "⚙️ Creating default .env file..."
            cat > .env << EOF
# Environment configuration
HOST=0.0.0.0
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
EOF
        fi
        
        # Start with Docker Compose
        docker-compose up -d
        
        echo "✅ Application started!"
        echo "🌐 API available at: http://localhost:8000"
        echo "📖 API docs at: http://localhost:8000/docs"
        echo ""
        echo "Use '$0 logs' to view logs"
        echo "Use '$0 stop' to stop the application"
        ;;
    
    stop)
        echo "🛑 Stopping application..."
        docker-compose down
        echo "✅ Application stopped!"
        ;;
    
    logs)
        echo "📋 Showing container logs..."
        docker-compose logs -f agent-paper-parser
        ;;
    
    clean)
        echo "🧹 Cleaning up Docker resources..."
        docker-compose down -v
        docker system prune -f
        docker image rm agent-paper-parser 2>/dev/null || true
        echo "✅ Cleanup completed!"
        ;;
    
    *)
        echo "❌ Unknown action: $ACTION"
        exit 1
        ;;
esac