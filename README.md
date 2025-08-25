# agent_paper_parser
 document QA with embeddings + LLM orchestration
Lightweight FastAPI project that ingests PDFs, creates sentence embeddings (sentence-transformers + FAISS), and exposes a retrieval-augmented QA endpoint. It includes an LLM orchestration layer (LangChain preferred) with optional OpenAI or Google Gemini backends and optional LangFuse logging.

Features
Download & parse a sample PDF and store metadata in papers.db.
Create chunked embeddings and index in FAISS (faiss.index) with metadata.json.
Search the FAISS index and serve a /qa endpoint that uses an LLM to answer using retrieved context.
Pluggable providers: openai, gemini, or local (via LangChain).
Configurable ingestion on startup and persistence for faster restarts.
