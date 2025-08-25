from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
import os
import logging
from app.search import search
from app.orchestrator import generate_answer

qa_router = APIRouter()
logger = logging.getLogger(__name__)


class QARequest(BaseModel):
    query: str
    # provider: 'openai'|'gemini'|'local'
    provider: Optional[str] = None


@qa_router.post("/qa")
async def qa(request: QARequest):
    context_chunks = search(request.query, top_k=5)
    # limit context size to avoid extremely long prompts
    context_text = "\n".join([c["chunk"] for c in context_chunks])
    if len(context_text) > 6000:
        context_text = context_text[:6000]
    prompt_text = f"You are a helpful assistant that answers questions using provided academic context.\nQuestion: {request.query}\nContext: {context_text}"

    # choose provider: explicit request -> env fallback -> default to openai
    provider = (request.provider or os.getenv("DEFAULT_PROVIDER") or "openai").lower()
    try:
        answer = generate_answer(prompt_text, provider=provider)
    except Exception as e:
        logger.exception("generate_answer failed")
        answer = f"[LLM error] {e}"

    return {"answer": answer, "sources": [c["paper_id"] for c in context_chunks]}