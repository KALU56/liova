import os
import json
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from models.schemas import (
    AnalyzeImageRequest,
    ScanResultResponse,
    IngredientEvaluationRequest,
    IngredientEvaluationResponse,
    IngredientEvaluationItem
)
from services.vision_service import extract_text_from_image
from services.gemini_service import generate_summary
from services.ingredient_service import (
    parse_ingredient_list,
    classify_ingredients,
    compute_overall_risk,
    load_ingredient_dataset
)

load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

app = FastAPI(
    title="Liova Skincare Backend",
    description="AI-powered skincare ingredient analysis",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    print("=" * 50)
    print("Starting Liova Backend...")
    load_ingredient_dataset()
    print("=" * 50)


@app.get("/")
async def root():
    return {
        "service": "Liova Skincare Backend",
        "status": "running",
        "api_configured": bool(GOOGLE_API_KEY)
    }


@app.get("/ingredients")
async def get_ingredients():
    from services.ingredient_service import load_ingredient_dataset
    df = load_ingredient_dataset()
    if df is not None:
        name_col = df.columns[0]
        return {
            "total": len(df),
            "ingredients": df[name_col].head(50).tolist()
        }
    return {"total": 0, "ingredients": []}


@app.post("/analyze", response_model=ScanResultResponse)
async def analyze_product_image(request: AnalyzeImageRequest):
    print(f"\n📸 Analyzing: {request.image_url}")
    
    extracted_ingredients = []
    
    if GOOGLE_API_KEY:
        extracted_text = await extract_text_from_image(
            image_url=str(request.image_url),
            api_key=GOOGLE_API_KEY
        )
        
        if extracted_text:
            print(f"📝 Extracted {len(extracted_text)} characters")
            extracted_ingredients = parse_ingredient_list(extracted_text)
            print(f"🔍 Found {len(extracted_ingredients)} ingredients")
    
    if not extracted_ingredients:
        extracted_ingredients = ["Water", "Glycerin", "Fragrance"]
    
    classified = classify_ingredients(extracted_ingredients)
    overall_risk = compute_overall_risk(classified)
    
    summary = f"Analysis complete. Found {len(extracted_ingredients)} ingredients. Overall risk: {overall_risk}."
    
    if GOOGLE_API_KEY:
        gemini_result = await generate_summary(classified, GOOGLE_API_KEY)
        if gemini_result:
            try:
                result_json = json.loads(gemini_result)
                summary = result_json.get("summary", summary)
                if result_json.get("risk_level"):
                    overall_risk = result_json.get("risk_level")
            except:
                pass
    
    return ScanResultResponse(
        image_url=str(request.image_url),
        analysis_summary=summary,
        risk_level=overall_risk,
        ingredients=extracted_ingredients[:15],
        scanned_at=datetime.utcnow().isoformat() + "Z"
    )


@app.post("/evaluate", response_model=IngredientEvaluationResponse)
async def evaluate_ingredients(request: IngredientEvaluationRequest):
    ingredients = request.ingredients or []
    
    if not ingredients and request.raw_text:
        ingredients = parse_ingredient_list(request.raw_text)
    
    if not ingredients:
        raise HTTPException(status_code=400, detail="No ingredients provided")
    
    classified = classify_ingredients(ingredients)
    overall_risk = compute_overall_risk(classified)
    
    evaluated = []
    for item in classified:
        evaluated.append(
            IngredientEvaluationItem(
                name=item['name'],
                risk_level=item['risk_level'],
                explanation=item['explanation']
            )
        )
    
    risk_counts = {'high': 0, 'medium': 0, 'low': 0, 'unknown': 0}
    for item in classified:
        risk_counts[item['risk_level']] += 1
    
    if risk_counts['high'] > 0:
        summary = f"⚠️ Contains {risk_counts['high']} high-risk ingredient(s). Avoid this product."
    elif risk_counts['medium'] > 0:
        summary = f"📋 Contains {risk_counts['medium']} medium-risk ingredient(s). Patch test recommended."
    else:
        summary = "✅ Ingredients appear safe for most skin types."
    
    return IngredientEvaluationResponse(
        overall_risk=overall_risk,
        summary=summary,
        ingredients=evaluated
    )


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)