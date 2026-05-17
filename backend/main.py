import json
import os
import re
from typing import List, Optional, Dict, Any

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from src.retrieve import Retriever

load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "").strip()
GOOGLE_MODEL = os.getenv("GOOGLE_MODEL", "gemini-1.5-flash").strip()
RETRIEVER_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2").strip()
DEFAULT_TOP_K = int(os.getenv("RAG_TOP_K", "5"))

app = FastAPI(
    title="Liova RAG Backend",
    description="Product Q&A with embeddings + FAISS retrieval + Gemini generation",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

retriever: Optional[Retriever] = None


class AskRequest(BaseModel):
    question: str = Field(..., min_length=2, description="User question")
    top_k: int = Field(default=DEFAULT_TOP_K, ge=1, le=20)


class AskResponse(BaseModel):
    question: str
    answer: str
    retrieved_contexts: List[str]
    recommended_products: List[str]
    suitability_summary: str
    best_skin_types: List[str]
    avoid_skin_types: List[str]
    confidence: str
    model: str


class AnalyzeImageRequest(BaseModel):
    image_base64: str = Field(..., min_length=20)
    mime_type: str = Field(default="image/jpeg")
    skin_type: str = Field(default="Unknown")
    top_k: int = Field(default=DEFAULT_TOP_K, ge=1, le=20)


class AnalyzeTextRequest(BaseModel):
    product_text: str = Field(..., min_length=4)
    skin_type: str = Field(default="Unknown")
    top_k: int = Field(default=DEFAULT_TOP_K, ge=1, le=20)


class ProductAnalysisResponse(BaseModel):
    your_skin: str
    product_contains: List[str]
    analysis: str
    suitability: str
    suggestion: str


async def call_gemini(prompt: str, json_mode: bool = False) -> str:
    if not GOOGLE_API_KEY:
        raise HTTPException(status_code=500, detail="GOOGLE_API_KEY is missing")

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{GOOGLE_MODEL}:generateContent?key={GOOGLE_API_KEY}"
    )
    generation_config = {"temperature": 0.2, "maxOutputTokens": 900}
    if json_mode:
        generation_config["responseMimeType"] = "application/json"

    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": generation_config,
    }

    try:
        async with httpx.AsyncClient(timeout=45.0) as client:
            response = await client.post(url, json=payload)
    except httpx.TimeoutException as exc:
        raise HTTPException(status_code=504, detail="Gemini request timed out") from exc
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=502, detail=f"Network error calling Gemini: {exc}"
        ) from exc

    if response.status_code != 200:
        error_body = response.text[:1000]
        raise HTTPException(
            status_code=502,
            detail=(
                f"Gemini API failed {response.status_code}. "
                f"Model='{GOOGLE_MODEL}'. Response={error_body}"
            ),
        )

    data = response.json()
    candidates = data.get("candidates", [])
    if not candidates:
        raise HTTPException(status_code=502, detail="Gemini returned no candidates")

    content = candidates[0].get("content", {})
    parts = content.get("parts", [])
    if not parts:
        raise HTTPException(status_code=502, detail="Gemini returned empty content")

    answer_text = parts[0].get("text", "").strip()
    if not answer_text:
        raise HTTPException(status_code=502, detail="Gemini returned blank answer")

    return answer_text


async def call_gemini_with_image(prompt: str, image_base64: str, mime_type: str) -> str:
    if not GOOGLE_API_KEY:
        raise HTTPException(status_code=500, detail="GOOGLE_API_KEY is missing")

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{GOOGLE_MODEL}:generateContent?key={GOOGLE_API_KEY}"
    )
    generation_config = {
        "temperature": 0.1,
        "maxOutputTokens": 1024,
        "responseMimeType": "application/json",
    }
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt},
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": image_base64,
                        }
                    },
                ]
            }
        ],
        "generationConfig": generation_config,
    }

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, json=payload)
    except httpx.TimeoutException as exc:
        raise HTTPException(status_code=504, detail="Gemini request timed out") from exc
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=502, detail=f"Network error calling Gemini: {exc}"
        ) from exc

    if response.status_code == 429:
        raise HTTPException(
            status_code=429,
            detail="AI quota is temporarily exhausted. Please wait and try again.",
        )
    if response.status_code != 200:
        error_body = response.text[:600]
        raise HTTPException(
            status_code=502,
            detail=f"Gemini image analysis failed {response.status_code}: {error_body}",
        )

    data = response.json()
    candidates = data.get("candidates", [])
    if not candidates:
        raise HTTPException(status_code=502, detail="Gemini returned no candidates")

    parts = candidates[0].get("content", {}).get("parts", [])
    if not parts:
        raise HTTPException(status_code=502, detail="Gemini returned empty content")

    return parts[0].get("text", "").strip()


def _extract_ingredients(text: str) -> List[str]:
    normalized = text.lower().replace("ingredients:", "")
    parts = re.split(r"[,.;\n]", normalized)
    items: List[str] = []
    for p in parts:
        token = re.sub(r"[^a-z0-9\-\s\(\)]", " ", p).strip()
        token = re.sub(r"\s+", " ", token)
        if len(token) >= 4:
            items.append(token)
    return list(dict.fromkeys(items))


def _parse_json_object(text: str) -> Dict[str, Any]:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?", "", text, flags=re.IGNORECASE).strip()
        text = re.sub(r"```$", "", text).strip()

    try:
        parsed = json.loads(text)
        if isinstance(parsed, dict):
            return parsed
    except json.JSONDecodeError:
        pass

    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise HTTPException(
            status_code=502,
            detail=f"AI returned invalid JSON: {text[:180]}",
        )
    try:
        return json.loads(text[start : end + 1])
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"AI returned invalid JSON: {text[:180]}",
        ) from exc


def _normalize_suitability(value: str) -> str:
    value_lower = value.lower()
    if "not" in value_lower or "avoid" in value_lower:
        return "Not Good"
    if "good" in value_lower and "not" not in value_lower:
        return "Good"
    return "Moderate"


async def _parse_or_repair_json(text: str) -> Dict[str, Any]:
    try:
        return _parse_json_object(text)
    except HTTPException:
        repair_prompt = f"""
Convert this malformed AI response into valid compact JSON only.
It must have exactly these keys:
your_skin, product_contains, analysis, suitability, suggestion

Malformed response:
{text[:1200]}
""".strip()
        repaired = await call_gemini(repair_prompt, json_mode=True)
        return _parse_json_object(repaired)


def _fallback_product_analysis(
    skin_type: str,
    ingredients: List[str],
    skin_analysis: Dict[str, Any],
) -> ProductAnalysisResponse:
    lower_skin = skin_type.lower()
    lower_ingredients = [item.lower() for item in ingredients]
    joined = " ".join(lower_ingredients)

    suitability = "Moderate"
    if lower_skin in skin_analysis.get("best", []):
        suitability = "Good"
    if lower_skin in skin_analysis.get("avoid", []):
        suitability = "Not Good"

    heavy_for_oily = any(
        word in joined
        for word in ["wax", "shea butter", "castor oil", "coconut oil", "lanolin"]
    )
    irritant = any(word in joined for word in ["fragrance", "parfum", "alcohol"])
    hydrating = any(
        word in joined
        for word in ["glycerin", "hyaluronic", "panthenol", "niacinamide"]
    )

    if lower_skin == "oily" and heavy_for_oily:
        suitability = "Not Good"
        analysis = "This product has heavy oils or waxes that may feel greasy on oily skin."
        suggestion = "Choose a lighter gel or oil-free product."
    elif lower_skin == "sensitive" and irritant:
        suitability = "Moderate"
        analysis = "This product includes fragrance or irritants that may bother sensitive skin."
        suggestion = "Patch test first or choose fragrance-free."
    elif hydrating:
        analysis = "This product contains hydrating ingredients that can support skin moisture."
        suggestion = "Use if it matches your skin type and patch test first."
    else:
        analysis = "This product may be okay for your skin, but it is not a strong match."
        suggestion = "Patch test before regular use."

    return ProductAnalysisResponse(
        your_skin=skin_type,
        product_contains=ingredients[:10],
        analysis=analysis,
        suitability=suitability,
        suggestion=suggestion,
    )


def _is_blank_ai_value(value: Any) -> bool:
    text = str(value or "").strip().lower()
    return text in {"", "n/a", "na", "none", "unknown", "not available"}


def _clean_ai_ingredients(value: Any, fallback: List[str]) -> List[str]:
    if not isinstance(value, list):
        return fallback[:10]

    cleaned = []
    fallback_lookup = {item.lower(): item for item in fallback}
    for raw in value:
        item = str(raw or "").strip()
        lower = item.lower()
        if _is_blank_ai_value(item) or len(item) < 4:
            continue
        # If Gemini clipped an ingredient prefix, restore the full extracted name.
        restored = next(
            (full for key, full in fallback_lookup.items() if key.startswith(lower)),
            item,
        )
        cleaned.append(restored)

    return list(dict.fromkeys(cleaned or fallback[:10]))[:10]


async def _build_product_analysis(
    skin_type: str,
    ingredients: List[str],
    product_text: str,
    top_k: int,
) -> ProductAnalysisResponse:
    if retriever is None:
        raise HTTPException(status_code=503, detail="Retriever is not loaded")

    retrieval_query = ", ".join(ingredients) if ingredients else product_text
    if not retrieval_query:
        raise HTTPException(status_code=422, detail="No product text found.")

    hits = retriever.search(query=retrieval_query, top_k=top_k)
    retrieved_texts = [item["text"] for item in hits]
    skin_analysis = _skin_type_analysis(hits)

    context_block = "\n\n".join(
        [f"Context {i + 1}:\n{text}" for i, text in enumerate(retrieved_texts)]
    )
    final_prompt = f"""
You are a cosmetic product analyzer.
Use ONLY the product ingredients, user skin type, and retrieved dataset context.
Return ONLY valid JSON with exactly these keys:
{{
  "your_skin": "{skin_type}",
  "product_contains": ["short ingredient names only"],
  "analysis": "one short sentence users can understand",
  "suitability": "Good or Not Good or Moderate",
  "suggestion": "one short recommendation"
}}

User skin type: {skin_type}
Detected ingredients: {", ".join(ingredients) if ingredients else "unknown"}
Product text: {product_text or "unknown"}
Dataset skin match: best={", ".join(skin_analysis["best"]) or "unclear"}, caution={", ".join(skin_analysis["avoid"]) or "unclear"}
Retrieved dataset context:
{context_block}
""".strip()
    final_text = await call_gemini(final_prompt, json_mode=True)
    try:
        final_json = await _parse_or_repair_json(final_text)
    except HTTPException:
        return _fallback_product_analysis(skin_type, ingredients, skin_analysis)

    cleaned_ingredients = _clean_ai_ingredients(
        final_json.get("product_contains"), ingredients
    )
    analysis = str(final_json.get("analysis", "")).strip()
    suggestion = str(final_json.get("suggestion", "")).strip()
    suitability = _normalize_suitability(str(final_json.get("suitability", "Moderate")))

    if (
        _is_blank_ai_value(analysis)
        or _is_blank_ai_value(suggestion)
        or not cleaned_ingredients
    ):
        return _fallback_product_analysis(skin_type, ingredients, skin_analysis)

    return ProductAnalysisResponse(
        your_skin=skin_type,
        product_contains=cleaned_ingredients,
        analysis=analysis[:220],
        suitability=suitability,
        suggestion=suggestion[:180],
    )


def _skin_type_analysis(hits: List[Dict[str, Any]]) -> Dict[str, Any]:
    skin_keys = ["dry", "normal", "oily", "sensitive", "combination"]
    totals = {k: 0 for k in skin_keys}
    count = 0
    for hit in hits:
        record = hit.get("record") or {}
        if not record:
            continue
        count += 1
        for k in skin_keys:
            value = str(record.get(k, "0")).strip().lower()
            if value in {"1", "1.0", "true"}:
                totals[k] += 1

    if count == 0:
        return {"best": [], "avoid": [], "ratios": {}}

    ratios = {k: totals[k] / count for k in skin_keys}
    best = [k for k, r in ratios.items() if r >= 0.6]
    avoid = [k for k, r in ratios.items() if r <= 0.25]
    return {"best": best, "avoid": avoid, "ratios": ratios}


def build_rag_prompt(
    question: str,
    retrieved_texts: List[str],
    matched_ingredients: List[str],
    best_skin_types: List[str],
    avoid_skin_types: List[str],
) -> str:
    context_block = "\n\n".join(
        [f"Context {i + 1}:\n{text}" for i, text in enumerate(retrieved_texts)]
    )
    return f"""
You are a skincare product assistant.
Answer the user only using the retrieved product contexts.
If the context is not enough, say that clearly and avoid making up facts.

User Question:
{question}

Retrieved Context:
{context_block}

Return a clear, practical answer in plain English.
Format:
1) Suitability: Good / Moderate / Not Recommended
2) Best Skin Types: short list
3) Avoid/Use Caution: short list
4) Why: very simple explanation using ingredient and dataset evidence
5) Cautions: short and practical
Use simple words a non-technical user can understand.
Matched Ingredients From User Input: {", ".join(matched_ingredients) if matched_ingredients else "none"}
Best Skin Types (from dataset score): {", ".join(best_skin_types) if best_skin_types else "unclear"}
Avoid/Use Caution (from dataset score): {", ".join(avoid_skin_types) if avoid_skin_types else "unclear"}
""".strip()


@app.on_event("startup")
async def startup_event() -> None:
    global retriever
    print(
        f"[startup] Loading retriever model='{RETRIEVER_MODEL}', "
        f"gemini_model='{GOOGLE_MODEL}', "
        f"api_key_configured={bool(GOOGLE_API_KEY)}"
    )
    retriever = Retriever.load(model_name=RETRIEVER_MODEL)
    print("[startup] Retriever loaded successfully")


@app.get("/health")
async def health() -> dict:
    return {
        "status": "ok",
        "retriever_ready": retriever is not None,
        "gemini_configured": bool(GOOGLE_API_KEY),
        "gemini_model": GOOGLE_MODEL,
    }


@app.post("/ask", response_model=AskResponse)
async def ask_question(request: AskRequest) -> AskResponse:
    if retriever is None:
        raise HTTPException(status_code=503, detail="Retriever is not loaded")

    hits = retriever.search(query=request.question, top_k=request.top_k)
    retrieved_texts = [item["text"] for item in hits]

    if not retrieved_texts:
        raise HTTPException(status_code=404, detail="No matching products found")

    extracted_ingredients = _extract_ingredients(request.question)
    skin_analysis = _skin_type_analysis(hits)
    best_skin_types = skin_analysis["best"]
    avoid_skin_types = skin_analysis["avoid"]
    prompt = build_rag_prompt(
        request.question,
        retrieved_texts,
        extracted_ingredients,
        best_skin_types,
        avoid_skin_types,
    )
    answer = await call_gemini(prompt)

    product_names: List[str] = []
    for hit in hits:
        record = hit.get("record") or {}
        name = str(record.get("name", "")).strip()
        brand = str(record.get("brand", "")).strip()
        if name:
            product_names.append(f"{name} ({brand})" if brand else name)
    product_names = product_names[:3]

    top_hit = hits[0]
    top_score = top_hit.get("score", 0.0)
    suitability = "Moderate"
    if top_score >= 0.7:
        suitability = "Good"
    elif top_score < 0.45:
        suitability = "Not Recommended"

    confidence = "Low"
    if top_score >= 0.75:
        confidence = "High"
    elif top_score >= 0.55:
        confidence = "Medium"

    return AskResponse(
        question=request.question,
        answer=answer,
        retrieved_contexts=retrieved_texts,
        recommended_products=product_names,
        suitability_summary=f"Top match score: {top_score:.2f} ({suitability})",
        best_skin_types=best_skin_types,
        avoid_skin_types=avoid_skin_types,
        confidence=confidence,
        model=GOOGLE_MODEL,
    )


@app.post("/analyze-image", response_model=ProductAnalysisResponse)
async def analyze_image(request: AnalyzeImageRequest) -> ProductAnalysisResponse:
    if retriever is None:
        raise HTTPException(status_code=503, detail="Retriever is not loaded")

    extraction_prompt = """
Read the cosmetic product label in this image.
Return ONLY valid JSON:
{
  "ingredients": ["ingredient 1", "ingredient 2"],
  "product_text": "short visible product description"
}
If ingredients are not visible, use an empty ingredients list.
""".strip()
    extraction_text = await call_gemini_with_image(
        extraction_prompt, request.image_base64, request.mime_type
    )
    extraction = _parse_json_object(extraction_text)
    ingredients = [str(x).strip() for x in extraction.get("ingredients", []) if str(x).strip()]
    product_text = str(extraction.get("product_text", "")).strip()

    retrieval_query = ", ".join(ingredients) if ingredients else product_text
    if not retrieval_query:
        raise HTTPException(
            status_code=422,
            detail="Could not read ingredients or product text from image.",
        )

    return await _build_product_analysis(
        skin_type=request.skin_type,
        ingredients=ingredients,
        product_text=product_text,
        top_k=request.top_k,
    )


@app.post("/analyze-text", response_model=ProductAnalysisResponse)
async def analyze_text(request: AnalyzeTextRequest) -> ProductAnalysisResponse:
    ingredients = _extract_ingredients(request.product_text)
    return await _build_product_analysis(
        skin_type=request.skin_type,
        ingredients=ingredients,
        product_text=request.product_text,
        top_k=request.top_k,
    )
