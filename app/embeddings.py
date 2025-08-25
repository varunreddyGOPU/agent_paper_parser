from sentence_transformers import SentenceTransformer
import faiss
import numpy as np
import os
import json
from typing import List

VECTOR_DIM = 768
MODEL_NAME = os.getenv("EMBED_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
INDEX_PATH = os.getenv("INDEX_PATH", "faiss.index")
METADATA_PATH = os.getenv("METADATA_PATH", "metadata.json")

# initialize embedder and index lazily to avoid heavy downloads on import
embedder = None
index = None


def get_embedder():
    global embedder
    if embedder is None:
        embedder = SentenceTransformer(MODEL_NAME)
    return embedder


def get_index():
    """Return a FAISS index initialized with the embedder dimension.

    If an index file exists at INDEX_PATH, load it. Otherwise create a new
    IndexFlatL2 with the embedding dimension determined from the embedder.
    """
    global index
    if index is not None:
        return index

    # ensure embedder exists so we can get the dimension
    emb = get_embedder()
    emb_dim = emb.get_sentence_embedding_dimension()

    if os.path.exists(INDEX_PATH):
        try:
            idx = faiss.read_index(INDEX_PATH)
            # if loaded index dimension mismatches, recreate
            if idx.d != emb_dim:
                idx = faiss.IndexFlatL2(emb_dim)
        except Exception:
            idx = faiss.IndexFlatL2(emb_dim)
    else:
        idx = faiss.IndexFlatL2(emb_dim)

    index = idx
    return index

# load metadata if present
if os.path.exists(METADATA_PATH):
    try:
        with open(METADATA_PATH, "r", encoding="utf8") as f:
            metadata = json.load(f)
    except Exception:
        metadata = []
else:
    metadata = []


def _chunk_text(text: str, size: int = 500) -> List[str]:
    # basic chunking by characters with trimming; can be replaced by smarter token-aware chunking
    chunks = [text[i:i+size].strip() for i in range(0, len(text), size)]
    return [c for c in chunks if c]


def _save_index_and_metadata():
    try:
        idx = get_index()
        faiss.write_index(idx, INDEX_PATH)
    except Exception:
        # If faiss write fails, don't crash the app; caller may log
        pass
    try:
        with open(METADATA_PATH, "w", encoding="utf8") as f:
            json.dump(metadata, f, ensure_ascii=False)
    except Exception:
        pass


def add_to_index(paper_id: int, text: str):
    embedder = get_embedder()
    idx = get_index()
    chunks = _chunk_text(text, size=500)
    if not chunks:
        return
    embeddings = embedder.encode(chunks)
    emb_np = np.asarray(embeddings, dtype="float32")
    if emb_np.ndim == 1:
        emb_np = emb_np.reshape(1, -1)
    # ensure embedding dimension matches index dimension
    if emb_np.shape[1] != idx.d:
        raise RuntimeError(f"Embedding dim {emb_np.shape[1]} does not match index dim {idx.d}")
    idx.add(emb_np)
    for c in chunks:
        metadata.append({"paper_id": paper_id, "chunk": c})
    _save_index_and_metadata()

