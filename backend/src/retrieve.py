import pickle
import re
from dataclasses import dataclass
from pathlib import Path
from typing import List, Dict, Any, Optional, Set

import faiss
import numpy as np
from sentence_transformers import SentenceTransformer


@dataclass
class Retriever:
    model: SentenceTransformer
    index: faiss.Index
    texts: List[str]
    records: List[Dict[str, Any]]

    @classmethod
    def load(
        cls,
        model_name: str = "all-MiniLM-L6-v2",
        index_path: str = "models/faiss_index.bin",
        texts_path: str = "models/texts.pkl",
        records_path: str = "models/records.pkl",
    ) -> "Retriever":
        index_file = Path(index_path)
        texts_file = Path(texts_path)
        records_file = Path(records_path)

        if not index_file.exists():
            raise FileNotFoundError(f"Missing FAISS index: {index_path}")
        if not texts_file.exists():
            raise FileNotFoundError(f"Missing texts file: {texts_path}")
        if not records_file.exists():
            raise FileNotFoundError(f"Missing records file: {records_path}")

        model = SentenceTransformer(model_name)
        index = faiss.read_index(str(index_file))
        with texts_file.open("rb") as f:
            texts = pickle.load(f)
        with records_file.open("rb") as f:
            records = pickle.load(f)

        return cls(model=model, index=index, texts=texts, records=records)

    @staticmethod
    def _extract_ingredients(text: str) -> Set[str]:
        text = text.lower()
        text = re.sub(r"ingredients?\s*:\s*", "", text)
        parts = re.split(r"[,.;\n]", text)
        tokens = set()
        for part in parts:
            token = re.sub(r"[^a-z0-9\-\s\(\)]", " ", part).strip()
            token = re.sub(r"\s+", " ", token)
            if len(token) >= 4:
                tokens.add(token)
        return tokens

    @staticmethod
    def _infer_skin_preferences(query: str) -> Set[str]:
        query_lower = query.lower()
        prefs = set()
        for key in ["dry", "normal", "oily", "sensitive", "combination"]:
            if key in query_lower:
                prefs.add(key)
        return prefs

    def search(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        candidate_k = min(max(top_k * 5, 20), len(self.texts))
        query_vector = self.model.encode([query])
        distances, indices = self.index.search(np.array(query_vector), candidate_k)

        query_ingredients = self._extract_ingredients(query)
        skin_prefs = self._infer_skin_preferences(query)

        results: List[Dict[str, Any]] = []
        for rank, idx in enumerate(indices[0]):
            if idx < 0 or idx >= len(self.texts):
                continue
            record: Optional[Dict[str, Any]] = None
            if idx < len(self.records):
                record = self.records[idx]

            item_ingredients = self._extract_ingredients(
                str(record.get("ingredients", "")) if record else self.texts[idx]
            )
            overlap_count = len(query_ingredients.intersection(item_ingredients))
            denom = max(1, len(query_ingredients))
            overlap_score = overlap_count / denom

            skin_score = 0.0
            if record and skin_prefs:
                for pref in skin_prefs:
                    value = str(record.get(pref, "0"))
                    if value in {"1", "1.0", "true", "True"}:
                        skin_score += 1.0
                skin_score /= max(1, len(skin_prefs))

            semantic_score = 1.0 / (1.0 + float(distances[0][rank]))
            hybrid_score = (0.65 * semantic_score) + (0.25 * overlap_score) + (0.10 * skin_score)

            results.append(
                {
                    "rank": rank + 1,
                    "text": self.texts[idx],
                    "distance": float(distances[0][rank]),
                    "semantic_score": round(semantic_score, 4),
                    "overlap_score": round(overlap_score, 4),
                    "skin_score": round(skin_score, 4),
                    "score": round(hybrid_score, 4),
                    "record": record,
                }
            )

        results.sort(key=lambda x: x["score"], reverse=True)
        top = results[:top_k]
        for i, item in enumerate(top):
            item["rank"] = i + 1
        return top
