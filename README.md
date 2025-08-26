# agent_paper_parser
Document QA with embeddings + LLM orchestration

Lightweight FastAPI project that ingests PDFs, creates sentence embeddings (sentence-transformers + FAISS), and exposes a retrieval-augmented QA endpoint. It includes an LLM orchestration layer (LangChain preferred) with optional OpenAI or Google Gemini backends and optional LangFuse logging.

## 🚀 Quick Start

### Automated Setup (Recommended)
```bash
git clone https://github.com/varunreddyGOPU/agent_paper_parser.git
cd agent_paper_parser
./scripts/setup.sh    # Complete environment setup
./scripts/start.sh     # Start the development server
```

### Docker Deployment
```bash
./scripts/docker.sh build
./scripts/docker.sh run
# Visit http://localhost:8000/docs
```

## 🔄 Automation & Triggers

This repository includes comprehensive automation triggers for CI/CD, deployments, and maintenance. See **[TRIGGERS.md](TRIGGERS.md)** for complete documentation.

**Available triggers:**
- 🔧 **CI/CD Pipeline** - Automatic testing on push/PR
- 🚀 **Deployment Workflow** - Automated deployments to staging/production  
- 📚 **Scheduled Ingestion** - Daily PDF processing at 2 AM UTC
- 🐳 **Docker Builds** - Multi-platform container images
- 🔧 **Manual Tasks** - QA testing, index rebuilding, health checks

**Quick trigger usage:**
```bash
# Local automation
./scripts/setup.sh     # Complete setup
./scripts/start.sh     # Start server  
./scripts/ingest.sh    # Ingest PDFs
./scripts/test.sh      # Run tests
./scripts/docker.sh    # Docker operations

# GitHub Actions (via web UI)
# - Deploy Application (manual)
# - Manual Tasks (various maintenance)
# - Scheduled PDF Ingestion (daily + manual)
```

Features
- Download & parse a sample PDF and store metadata in papers.db (SQLite).
- Create chunked embeddings and index in FAISS (faiss.index) with metadata.json.
- Search the FAISS index and serve a /qa endpoint that uses an LLM to answer using retrieved context.
- Pluggable providers: openai, gemini, or local (via LangChain).
- Configurable ingestion on startup and persistence for faster restarts.

Repository
- GitHub: https://github.com/varunreddyGOPU/agent_paper_parser

Note on this guide
- This guide is tailored to the described architecture of this repo.
- If your app entrypoint or ingestion script file names differ, see “Discover the entrypoint” for a quick way to adapt commands.

--------------------------------------------------------------------------------

1) Prerequisites

- Python 3.9–3.11 (3.10 recommended)
- pip ≥ 23
- Git
- Optional: curl (for quick API testing)

OS notes
- faiss-cpu installs via pip on macOS/Linux/Windows. If you see build errors on Linux, ensure OpenBLAS is available or stick to prebuilt wheels. Apple Silicon works with the pip wheel (Python 3.10+ recommended).

--------------------------------------------------------------------------------

2) Setup

Clone and enter the repo
```bash
git clone https://github.com/varunreddyGOPU/agent_paper_parser.git
cd agent_paper_parser
```

Create a virtual environment and install dependencies
```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

Environment variables
```bash
cp .env.example .env
# Edit .env and set:
#   PROVIDER=openai|gemini|local
#   OPENAI_API_KEY or GOOGLE_API_KEY
#   EMBEDDING_MODEL and LLM_MODEL if you want different defaults
```

--------------------------------------------------------------------------------

3) Ingest PDFs (build embeddings + FAISS index)

You can either:
- Use a CLI ingestion module (recommended), or
- Use an HTTP endpoint (if implemented in your code)

CLI ingestion (preferred)
- If your repo includes an ingestion module (commonly app/ingest.py), run:
```bash
# Local PDF
python -m app.ingest --pdf path/to/paper.pdf --chunk-size 800 --chunk-overlap 100

# Remote PDF URL (example: "Attention Is All You Need")
python -m app.ingest --pdf-url https://arxiv.org/pdf/1706.03762.pdf

# Rebuild embeddings/index if you changed EMBEDDING_MODEL
python -m app.ingest --rebuild
```

HTTP ingestion (optional, if endpoint exists)
```bash
curl -X POST http://localhost:8000/ingest \
  -H "Content-Type: application/json" \
  -d '{"pdf_url":"https://arxiv.org/pdf/1706.03762.pdf"}'
```

What you should see after ingestion
- data/papers.db (SQLite with paper metadata)
- data/faiss.index (FAISS index)
- data/metadata.json (chunk metadata such as text spans and page refs)
- data/originals/ (optional: raw PDF storage)

Paths are configurable in .env:
- DATA_DIR, DB_PATH, INDEX_PATH, METADATA_PATH

--------------------------------------------------------------------------------

4) Run the API

Default uvicorn command (adjust module path if needed):
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

If your entrypoint differs, replace app.main:app with your module path (e.g., app.api:app, app.server:app, main:app).

Health check
```bash
curl http://localhost:8000/health
# Expect: {"status":"ok"} (or similar)
```

--------------------------------------------------------------------------------

5) Ask questions (RAG /qa)

Example request
```bash
curl -X POST http://localhost:8000/qa \
  -H "Content-Type: application/json" \
  -d '{
    "question":"What problem does the paper address?",
    "top_k":4,
    "temperature":0.1
  }'
```

Typical behavior
- Retrieves top_k chunks from FAISS.
- Crafts a prompt with retrieved context.
- Calls the configured LLM provider (OpenAI, Gemini, or a local model via LangChain).
- Returns an answer and optionally source snippets/metadata.

--------------------------------------------------------------------------------

6) Configure Providers and Models

OpenAI
```dotenv
PROVIDER=openai
OPENAI_API_KEY=sk-...
LLM_MODEL=gpt-4o-mini
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

Google Gemini
```dotenv
PROVIDER=gemini
GOOGLE_API_KEY=...
LLM_MODEL=gemini-1.5-flash
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

Local (via LangChain)
```dotenv
PROVIDER=local
# Configure your local LLM adapter in code (e.g., Ollama, llama.cpp).
```

Optional observability (LangFuse)
```dotenv
LANGFUSE_PUBLIC_KEY=
LANGFUSE_SECRET_KEY=
LANGFUSE_HOST=
```

--------------------------------------------------------------------------------

7) Data and persistence

- Index + metadata persist across restarts:
  - INDEX_PATH (default: ./data/faiss.index)
  - METADATA_PATH (default: ./data/metadata.json)
  - DB_PATH (default: ./data/papers.db)
- Rebuild if you change the embedding model:
```bash
python -m app.ingest --rebuild
```

--------------------------------------------------------------------------------

8) Discover the entrypoint (if uvicorn path is unknown)

Find the FastAPI app instance
```bash
# Look for FastAPI() creation
grep -R "FastAPI(" -n app | sed -n '1,200p'

# Typical results:
# app/main.py: app = FastAPI(...)
# Then use: uvicorn app.main:app --port 8000 --reload
```

Find the ingestion CLI
```bash
# Look for a module that loads PDFs or creates FAISS indexes
grep -R "faiss" -n app | sed -n '1,200p'
grep -R "sentence_transformers" -n app | sed -n '1,200p'
grep -R -E "pypdf|pdfminer" -n app | sed -n '1,200p'
```

If you don’t find a CLI, ingestion may happen:
- On startup (the app ingests a sample PDF automatically), or
- Via an /ingest HTTP endpoint.

--------------------------------------------------------------------------------

9) Troubleshooting

- faiss-cpu install issues
  - Upgrade build tooling and try again:
    ```bash
    pip install --upgrade pip setuptools wheel
    pip install faiss-cpu
    ```
  - Consider Python 3.10+ for best wheel availability.

- Vector dimension mismatch after changing EMBEDDING_MODEL
  - Rebuild the index:
    ```bash
    python -m app.ingest --rebuild
    ```

- 401/403 calling LLMs
  - Confirm PROVIDER and the corresponding API key in .env.
  - Ensure LLM_MODEL exists and is accessible for your account/region.

- PDF parsing fails or returns garbled text
  - Switch parser libraries in code (pypdf vs pdfminer.six) or adjust your extraction logic.

--------------------------------------------------------------------------------

10) Development

Formatting and lint
```bash
pip install ruff black
ruff check .
black .
```

Run tests (if present)
```bash
pytest -q
```

--------------------------------------------------------------------------------

License
Apache 2.0 — see LICENSE.
