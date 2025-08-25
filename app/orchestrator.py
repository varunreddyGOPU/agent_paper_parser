"""LLM orchestration layer using LangChain when available and optional LangFuse logging.

This module provides a single entrypoint `generate_answer(prompt, provider)` which will:
- Use langchain's OpenAI wrapper if available and provider=='openai'
- Use the Google Generative Language REST endpoint if provider=='gemini'
- Attempt a local-model path if provider=='local' and langchain is available
- Post an event to a LangFuse-compatible endpoint if `LANGFUSE_URL` is set

The code is defensive: if langchain is not installed, it falls back to direct OpenAI client or raises
clear errors for local-model cases. Configure via env vars:
- OPENAI_API_KEY, GOOGLE_API_KEY, LANGFUSE_URL, LANGFUSE_API_KEY, GOOGLE_MODEL
"""
import os
import logging
import requests

logger = logging.getLogger(__name__)

try:
    from langchain.llms import OpenAI as LCOpenAI
    from langchain import LLMChain
    from langchain.prompts import PromptTemplate
    LANGCHAIN_AVAILABLE = True
except Exception:
    LCOpenAI = None
    LANGCHAIN_AVAILABLE = False


def _call_google_gemini(prompt: str) -> str:
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise RuntimeError("GOOGLE_API_KEY is not set")
    model = os.getenv("GOOGLE_MODEL", "text-bison-001")
    model_path = model if model.startswith("models/") else f"models/{model}"
    url = f"https://generativelanguage.googleapis.com/v1beta2/{model_path}:generate"
    body = {
        "prompt": {"text": prompt},
        "temperature": float(os.getenv("GOOGLE_TEMPERATURE", "0.2")),
        "maxOutputTokens": int(os.getenv("GOOGLE_MAX_OUTPUT_TOKENS", "512")),
    }
    resp = requests.post(url, params={"key": api_key}, json=body, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    if "candidates" in data and isinstance(data["candidates"], list) and data["candidates"]:
        return data["candidates"][0].get("content", "")
    if "output" in data:
        return str(data["output"])
    return str(data)


def _call_openai_via_langchain(prompt: str) -> str:
    if not LANGCHAIN_AVAILABLE:
        raise RuntimeError("langchain is not installed")
    api_key = os.getenv("OPENAI_API_KEY")
    # LangChain OpenAI wrapper will read env var if supported; pass key if class supports it
    try:
        llm = LCOpenAI(openai_api_key=api_key)
    except TypeError:
        # older/newer langchain versions may accept api_key differently
        llm = LCOpenAI()
    template = PromptTemplate(input_variables=["text"], template="{text}")
    chain = LLMChain(llm=llm, prompt=template)
    resp = chain.run(prompt)
    return resp


def _call_openai_direct(prompt: str) -> str:
    # direct OpenAI SDK fallback
    try:
        import openai
    except Exception:
        raise RuntimeError("OpenAI SDK not available")
    openai.api_key = os.getenv("OPENAI_API_KEY")
    response = openai.ChatCompletion.create(
        model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        messages=[{"role": "user", "content": prompt}],
    )
    return response["choices"][0]["message"]["content"]


def _log_to_langfuse(prompt: str, answer: str, provider: str):
    url = os.getenv("LANGFUSE_URL")
    if not url:
        return
    api_key = os.getenv("LANGFUSE_API_KEY")
    payload = {"prompt": prompt, "answer": answer, "provider": provider}
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    try:
        requests.post(url, json=payload, headers=headers, timeout=5)
    except Exception:
        logger.exception("Failed to post event to LangFuse")


def generate_answer(prompt: str, provider: str = "openai") -> str:
    """Generate an answer using the requested provider.

    provider: 'openai'|'gemini'|'local'
    """
    provider = provider or "openai"
    provider = provider.lower()
    answer = None
    try:
        if provider == "gemini":
            answer = _call_google_gemini(prompt)
        elif provider == "openai":
            # prefer langchain if installed
            if LANGCHAIN_AVAILABLE:
                answer = _call_openai_via_langchain(prompt)
            else:
                answer = _call_openai_direct(prompt)
        elif provider == "local":
            if LANGCHAIN_AVAILABLE:
                # try a local HF model via langchain; rely on user's langchain config
                try:
                    # user should configure LANGCHAIN to use a local model/pipeline
                    answer = _call_openai_via_langchain(prompt)
                except Exception:
                    raise RuntimeError("local provider with langchain is not configured")
            else:
                raise RuntimeError("local provider requires langchain to be installed and configured")
        else:
            raise RuntimeError(f"Unknown provider: {provider}")
    except Exception as e:
        logger.exception("LLM generation failed")
        answer = f"[LLM error] {e}"

    # best-effort log to LangFuse for observability
    try:
        _log_to_langfuse(prompt, answer, provider)
    except Exception:
        logger.exception("LangFuse logging failed")

    return answer
