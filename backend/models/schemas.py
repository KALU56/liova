from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, HttpUrl


class AnalyzeImageRequest(BaseModel):
    image_url: HttpUrl


class ScanResultResponse(BaseModel):
    image_url: str
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