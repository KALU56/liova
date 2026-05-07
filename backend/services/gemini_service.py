import httpx
import json


async def call_gemini_api(prompt: str, api_key: str, model: str = "gemini-1.5-pro") -> str:
    if not api_key:
        return ""
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    
    payload = {
        "contents": [{
            "parts": [{"text": prompt}]
        }],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 500
        }
    }
    
    async with httpx.AsyncClient(timeout=45.0) as client:
        response = await client.post(url, json=payload)
        
        if response.status_code != 200:
            print(f"Gemini API error: {response.status_code}")
            return ""
        
        result = response.json()
        candidates = result.get("candidates", [])
        if candidates:
            content = candidates[0].get("content", {})
            parts = content.get("parts", [])
            if parts:
                return parts[0].get("text", "")
        
        return ""


async def generate_summary(ingredients_with_risks: list, api_key: str) -> str:
    if not ingredients_with_risks:
        return '{"risk_level": "unknown", "summary": "No ingredients to analyze."}'
    
    ingredient_text = "\n".join([
        f"- {item['name']}: {item['risk_level']} risk - {item.get('explanation', '')}"
        for item in ingredients_with_risks[:15]
    ])
    
    prompt = f"""
You are a skincare safety expert. Analyze these ingredients and provide a short summary.

INGREDIENTS AND THEIR RISKS:
{ingredient_text}

Return ONLY valid JSON with:
- "risk_level": "low", "medium", or "high"
- "summary": one sentence for the user (max 150 characters)

Example: {{"risk_level": "medium", "summary": "Contains potential irritants. Patch test recommended."}}
"""
    
    response = await call_gemini_api(prompt, api_key)
    
    if response:
        try:
            start = response.find('{')
            end = response.rfind('}') + 1
            if start != -1 and end != 0:
                return response[start:end]
        except:
            pass
    
    return json.dumps({
        "risk_level": "unknown",
        "summary": "Analysis complete. Check individual ingredients."
    })