# Triggers and Automation

This repository includes comprehensive automation triggers to run the agent_paper_parser code in various scenarios.

## 🚀 Quick Start

### Setup and Run Locally
```bash
# Setup the application
./scripts/setup.sh

# Start the development server
./scripts/start.sh

# Ingest sample PDFs
./scripts/ingest.sh

# Run health checks
./scripts/test.sh
```

### Docker Deployment
```bash
# Build and run with Docker
./scripts/docker.sh build
./scripts/docker.sh run

# View logs
./scripts/docker.sh logs

# Stop the application
./scripts/docker.sh stop
```

## 🔄 GitHub Actions Workflows

### 1. CI/CD Pipeline (`.github/workflows/ci.yml`)
**Triggers:** Push to main/develop branches, Pull Requests

**What it does:**
- Tests the application on Python 3.9, 3.10, 3.11
- Runs linting and import tests
- Tests server startup and health endpoints
- Creates build artifacts for main branch pushes
- Caches dependencies for faster builds

**Usage:** Automatically runs on code changes

### 2. Deployment Workflow (`.github/workflows/deploy.yml`)
**Triggers:** Manual dispatch, Version tags (v*)

**What it does:**
- Creates deployment packages
- Generates systemd service files
- Creates deployment scripts
- Supports staging and production environments

**Usage:**
```bash
# Manual deployment via GitHub Actions UI
# 1. Go to Actions tab in GitHub
# 2. Select "Deploy Application"
# 3. Click "Run workflow"
# 4. Choose environment and version
```

### 3. Scheduled PDF Ingestion (`.github/workflows/ingest.yml`)
**Triggers:** Daily at 2 AM UTC, Manual dispatch

**What it does:**
- Downloads and processes PDFs automatically
- Updates the FAISS index with new embeddings
- Supports custom PDF URLs via manual trigger
- Creates backup artifacts

**Usage:**
- Runs automatically daily
- Manual trigger allows custom PDF ingestion
- Can rebuild the entire index if needed

### 4. Manual Tasks (`.github/workflows/manual-tasks.yml`)
**Triggers:** Manual dispatch only

**Available tasks:**
- `test-qa-endpoint`: Test the QA functionality
- `rebuild-embeddings`: Rebuild the FAISS index
- `clean-database`: Remove duplicate entries
- `backup-data`: Create data backups
- `health-check`: System health validation
- `run-sample-queries`: Test with sample questions

**Usage:**
```bash
# Via GitHub Actions UI:
# 1. Go to Actions tab
# 2. Select "Manual Tasks"
# 3. Choose task and parameters
# 4. Run workflow
```

### 5. Docker Build and Push (`.github/workflows/docker.yml`)
**Triggers:** Push to main, Tags, Pull Requests, Manual dispatch

**What it does:**
- Builds multi-platform Docker images (amd64, arm64)
- Pushes to GitHub Container Registry
- Runs container smoke tests
- Creates deployment instructions

**Usage:** Automatically builds Docker images on code changes

## 📁 Automation Scripts

### `scripts/setup.sh`
Complete environment setup including:
- Virtual environment creation
- Dependency installation
- Database initialization
- Default configuration

### `scripts/start.sh`
Development server startup with:
- Environment activation
- Optional ingestion on startup
- Hot-reload enabled

### `scripts/ingest.sh`
PDF ingestion with options:
```bash
./scripts/ingest.sh                                          # Sample ingestion
./scripts/ingest.sh --pdf-url https://example.com/paper.pdf  # Custom PDF
./scripts/ingest.sh --rebuild                                # Rebuild index
```

### `scripts/test.sh`
Comprehensive testing:
- Import validation
- Server health checks
- Dependency verification
- Database validation

### `scripts/docker.sh`
Docker operations:
```bash
./scripts/docker.sh build    # Build image
./scripts/docker.sh run      # Start with compose
./scripts/docker.sh logs     # View logs
./scripts/docker.sh stop     # Stop containers
./scripts/docker.sh clean    # Cleanup
```

## 🐳 Docker Deployment

### Using Docker Compose
```bash
# Clone and start
git clone https://github.com/varunreddyGOPU/agent_paper_parser.git
cd agent_paper_parser
docker-compose up -d
```

### Using Pre-built Images
```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/varunreddygpu/agent_paper_parser:main

# Run with volume mounts
docker run -d -p 8000:8000 \
  --name agent-paper-parser \
  -v $(pwd)/data:/app/data \
  ghcr.io/varunreddygpu/agent_paper_parser:main
```

## ⚙️ Configuration

### Environment Variables
Create a `.env` file with:
```bash
# Server
HOST=0.0.0.0
PORT=8000

# LLM Provider
PROVIDER=openai|gemini|local
OPENAI_API_KEY=your_key_here
GOOGLE_API_KEY=your_key_here

# Models
LLM_MODEL=gpt-4o-mini
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2

# Startup
INGEST_ON_STARTUP=0|1
```

### Trigger Schedules
- **Daily Ingestion**: 2 AM UTC (configurable in `.github/workflows/ingest.yml`)
- **CI/CD**: On every push/PR
- **Docker Builds**: On main branch changes and tags

## 🔧 Customization

### Adding New Triggers
1. Create workflow in `.github/workflows/`
2. Use existing patterns for consistency
3. Add appropriate permissions and secrets

### Custom Ingestion Sources
Modify `scripts/ingest.sh` or create new workflows to:
- Monitor RSS feeds for new papers
- Integrate with academic databases
- Process local file directories

### Deployment Targets
Extend `deploy.yml` workflow for:
- Cloud platforms (AWS, GCP, Azure)
- Kubernetes clusters
- Multiple environments

## 🚨 Troubleshooting

### Common Issues
1. **Missing Dependencies**: Run `./scripts/setup.sh`
2. **Port Conflicts**: Change PORT in `.env` file
3. **Docker Permission**: Add user to docker group
4. **Workflow Failures**: Check GitHub Actions logs

### Debug Mode
Enable detailed logging:
```bash
export LANGCHAIN_VERBOSE=true
export LANGCHAIN_TRACING=true
./scripts/start.sh
```

## 📊 Monitoring

### Health Endpoints
- `GET /docs` - API documentation
- `GET /openapi.json` - OpenAPI schema

### Workflow Artifacts
- Build packages (30 day retention)
- Ingestion results (7 day retention)
- Test reports and logs

### Container Health
```bash
# Check container health
docker ps
docker logs agent-paper-parser

# Monitor resources
docker stats agent-paper-parser
```