from datetime import datetime
import json
import os
import re
from typing import List, Optional

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, HttpUrl

from ingredient_data import SMALL_INGREDIENT_DATA

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GOOGLE_MODEL = os.getenv("GOOGLE_MODEL", "gemini-1.5")
GOOGLE_API_URL = f"https://generativelanguage.googleapis.com/v1beta2/models/{GOOGLE_MODEL}:generate"

app = FastAPI(
    title="Liova Skincare Backend",
    description="Simple backend for skincare ingredient analysis and image-based scan results.",
    version="0.1.0",
)

LOW_RISK_PATTERNS = [
    "water",
    "aqua",
    "glycerin",
    "niacinamide",
    "hyaluronic",
    "ceramide",
    "squalane",
    "allantoin",
    "panthenol",
    "aloe",
    "sunflower",
    "jojoba",
    "sheabutter",
    "butyrospermum",
    "coconut",
    "caprylic",
    "capric",
    "stearic",
    "oleic",
    "palmitic",
    "tocopherol",
    "vitamin e",
]

MEDIUM_RISK_PATTERNS = [
    "citric",
    "glycolic",
    "lactic",
    "malic",
    "mandelic",
    "salicylic",
    "alpha hydroxy",
    "beta hydroxy",
    "fragrance",
    "parfum",
    "phenoxyethanol",
    "bht",
    "cocamidopropyl",
    "methylisothiazolinone",
    "methylchloroisothiazolinone",
    "benzyl alcohol",
    "essential oil",
    "menthol",
    "eucalyptus",
    "peppermint",
    "alcohol denat",
    "isopropyl alcohol",
    "sodium lauryl",
    "sodium laureth",
]

HIGH_RISK_PATTERNS = [
    "retinol",
    "retinyl",
    "tretinoin",
    "adapalene",
    "benzoyl peroxide",
    "hydroquinone",
    "formaldehyde",
    "oxybenzone",
    "octinoxate",
    "octocrylene",
]

RISK_EXPLANATIONS = {
    "low": "This ingredient is usually gentle for most skin types.",
    "medium": "This ingredient may cause irritation in sensitive skin or at higher concentrations.",
    "high": "This ingredient is more active and can increase irritation or dryness for everyday use.",
    "unknown": "Limited data available for this ingredient.",
}


def normalize_name(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", name.lower())


def get_dataset_entry(name: str) -> Optional[dict]:
    normalized_name = normalize_name(name)
    for key, entry in SMALL_INGREDIENT_DATA.items():
        if normalize_name(key) == normalized_name:
            return entry
    return None


def classify_ingredient(name: str) -> str:
    dataset_entry = get_dataset_entry(name)
    if dataset_entry:
        return dataset_entry["risk_level"]

    normalized = normalize_name(name)
    if any(pattern.replace(" ", "") in normalized for pattern in HIGH_RISK_PATTERNS):
        return "high"
    if any(pattern.replace(" ", "") in normalized for pattern in MEDIUM_RISK_PATTERNS):
        return "medium"
    if any(pattern.replace(" ", "") in normalized for pattern in LOW_RISK_PATTERNS):
        return "low"
    return "unknown"


def parse_ingredient_names(raw_text: str) -> List[str]:
    if not raw_text:
        return []

    parts = re.split(r"[\n\r,;()]+", raw_text)
    names = [part.strip() for part in parts if part.strip()]
    return list(dict.fromkeys(names))


def compute_overall_risk(risk_levels: List[str]) -> str:
    if "high" in risk_levels:
        return "high"
    if "medium" in risk_levels or "unknown" in risk_levels:
        return "medium"
    return "low"


def build_rag_context(ingredients: List[str]) -> str:
    lines = [
        f"{name}: {get_dataset_entry(name)['risk_level']} - {get_dataset_entry(name)['explanation']}"
        if get_dataset_entry(name)
        else f"{name}: unknown local entry."
        for name in ingredients
    ]
    return "\n".join(lines)


async def call_gemini_api(prompt: str) -> str:
    if not GOOGLE_API_KEY:
        raise HTTPException(status_code=503, detail="Google API key not configured.")

    headers = {
        "Content-Type": "application/json",
    }
    payload = {
        "prompt": {
            "text": prompt,
        },
        "temperature": 0.2,
        "maxOutputTokens": 400,
    }
    url = f"{GOOGLE_API_URL}?key={GOOGLE_API_KEY}"

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, headers=headers, json=payload)
        if response.status_code != 200:
            raise HTTPException(
                status_code=502,
                detail=f"Gemini API request failed ({response.status_code}): {response.text}",
            )
        result = response.json()
        candidates = result.get("candidates")
        if isinstance(candidates, list) and candidates:
            return candidates[0].get("output", "No response generated.")
        raise HTTPException(status_code=502, detail="Gemini API returned unexpected response format.")


@app.get("/ingredient-dataset")
async def ingredient_dataset():
    return {"ingredients": SMALL_INGREDIENT_DATA}


class AnalyzeImageRequest(BaseModel):
    image_url: HttpUrl


class ScanResultResponse(BaseModel):
    image_url: HttpUrl
    analysis_summary: str
    risk_level: str
    ingredients: List[str]
    scanned_at: str


class IngredientEvaluationRequest(BaseModel):
    ingredients: Optional[List[str]] = None
    raw_text: Optional[str] = None


class IngredientEvaluationItem(BaseModel):
    name: str
    risk_level: str
    explanation: str


class IngredientEvaluationResponse(BaseModel):
    overall_risk: str
    summary: str
    ingredients: List[IngredientEvaluationItem]


SAMPLE_INGREDIENTS = [
    "Water",
    "Glycerin",
    "Niacinamide",
    "Butylene Glycol",
    "Citric Acid",
    "Fragrance",
]


@app.post("/analyze", response_model=ScanResultResponse)
async def analyze_image(request: AnalyzeImageRequest):
    rag_context = build_rag_context(SAMPLE_INGREDIENTS)
    prompt = (
        "You are a skincare ingredient safety assistant. Use the local ingredient dataset below to provide a conservative skin safety analysis. "
        "The backend received a product photo URL from Cloudinary. Use the URL for reference but do not invent ingredient names from the image. "
        "If the image content is not available, respond with conservative guidance and include the dataset results where appropriate. "
        "Return valid JSON only with fields: overall_risk, summary, and ingredients. "
        "Each ingredient object should include name, risk_level, and explanation.\n\n"
        f"LOCAL DATA:\n{rag_context}\n\n"
        f"IMAGE URL: {request.image_url}"
    )

    llm_output = await call_gemini_api(prompt)
    try:
        result = json.loads(llm_output)
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Gemini returned invalid JSON response.") from exc

    ingredients = []
    for item in (result.get('ingredients', []) or []):
        if isinstance(item, dict):
            ingredients.append(str(item.get('name', '')))

    return ScanResultResponse(
        image_url=request.image_url,
        analysis_summary=result.get('summary', 'Unable to generate analysis.'),
        risk_level=result.get('overall_risk', 'unknown'),
        ingredients=ingredients,
        scanned_at=datetime.utcnow().isoformat() + "Z",
    )


@app.post("/evaluate", response_model=IngredientEvaluationResponse)
async def evaluate_ingredients(request: IngredientEvaluationRequest):
    ingredients = request.ingredients or []
    if not ingredients and request.raw_text:
        ingredients = parse_ingredient_names(request.raw_text)

    if not ingredients:
        raise HTTPException(status_code=400, detail="No ingredient names were provided.")

    evaluated = []
    risk_levels = []
    for name in ingredients:
        risk_level = classify_ingredient(name)
        dataset_entry = get_dataset_entry(name)
        explanation = (
            dataset_entry["explanation"]
            if dataset_entry
            else RISK_EXPLANATIONS.get(risk_level, RISK_EXPLANATIONS["unknown"])
        )
        evaluated.append(
            IngredientEvaluationItem(
                name=name.strip(),
                risk_level=risk_level,
                explanation=explanation,
            )
        )
        risk_levels.append(risk_level)

    overall_risk = compute_overall_risk(risk_levels)
    summary = (
        "Most ingredients are low or medium risk for daily use, but some items may be irritating for sensitive skin."
        if overall_risk != "low"
        else "The ingredient list appears generally mild for everyday skin use."
    )

    return IngredientEvaluationResponse(
        overall_risk=overall_risk,
        summary=summary,
        ingredients=evaluated,
    )


@app.post("/evaluate-rag", response_model=IngredientEvaluationResponse)
async def evaluate_ingredients_rag(request: IngredientEvaluationRequest):
    ingredients = request.ingredients or []
    if not ingredients and request.raw_text:
        ingredients = parse_ingredient_names(request.raw_text)

    if not ingredients:
        raise HTTPException(status_code=400, detail="No ingredient names were provided.")

    rag_context = build_rag_context(ingredients)
    prompt = (
        "Evaluate these skincare ingredients with a conservative safety view using the local dataset. "
        "Give a short overall risk and simple skin safety explanations. Do not give medical advice. "
        "Reply only in valid JSON with overall_risk, summary, and ingredients.\n\n"
        f"LOCAL DATA:\n{rag_context}\n\n"
        f"INGREDIENTS TO EVALUATE: {', '.join(ingredients)}"
    )

    llm_output = await call_gemini_api(prompt)
    try:
        result = json.loads(llm_output)
    except Exception as exc:
        raise HTTPException(status_code=502, detail="LLM returned invalid JSON response.") from exc

    return IngredientEvaluationResponse(**result)
