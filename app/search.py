from app.embeddings import get_embedder, get_index, metadata
import numpy as np


def search(query: str, top_k: int = 5):
    # Return empty if index has no vectors
    try:
        idx = get_index()
        total = int(idx.ntotal)
    except Exception:
        total = 0
    if total == 0:
        return []

    embedder = get_embedder()
    q_emb = np.asarray(embedder.encode([query]), dtype="float32")
    if q_emb.ndim == 1:
        q_emb = q_emb.reshape(1, -1)
    k = min(top_k, total)
    D, I = idx.search(q_emb, k)
    results = []
    for idx in I[0]:
        if 0 <= idx < len(metadata):
            results.append(metadata[idx])
    return results