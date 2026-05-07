import base64
import httpx


async def download_image_from_url(image_url: str) -> bytes:
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.get(image_url)
        if response.status_code != 200:
            raise Exception(f"Failed to download image: {response.status_code}")
        return response.content


async def extract_text_from_image(image_url: str, api_key: str) -> str:
    try:
        image_bytes = await download_image_from_url(image_url)
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        vision_url = f"https://vision.googleapis.com/v1/images:annotate?key={api_key}"
        
        payload = {
            "requests": [{
                "image": {"content": image_base64},
                "features": [{"type": "TEXT_DETECTION"}],
                "imageContext": {"languageHints": ["en"]}
            }]
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(vision_url, json=payload)
        
        if response.status_code != 200:
            return ""
        
        result = response.json()
        responses = result.get("responses", [])
        if responses:
            text_annotations = responses[0].get("textAnnotations", [])
            if text_annotations:
                return text_annotations[0].get("description", "")
        
        return ""
        
    except Exception as e:
        print(f"Vision API error: {e}")
        return ""