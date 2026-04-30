# Liova Backend

A Python FastAPI backend for the Lio skincare app. It receives Cloudinary image URLs, uses Google Gemini and a local ingredient dataset to analyze skincare ingredients, and returns the result to the mobile app.

## Install

```bash
cd backend
python3 -m pip install -r requirements.txt
```

## Run

```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Required environment variables

Set your Google API key before running the backend. You can either export them or create a `backend/.env` file:

```bash
# Option 1: Export in shell
export GOOGLE_API_KEY="your_google_api_key"
export GOOGLE_MODEL="gemini-1.5"

# Option 2: Create backend/.env file
echo "GOOGLE_API_KEY=your_google_api_key" > backend/.env
echo "GOOGLE_MODEL=gemini-1.5" >> backend/.env
```

The backend reads `GOOGLE_API_KEY` and `GOOGLE_MODEL` from the environment.

## Endpoints

- `POST /analyze`
  - Request body: `{ "image_url": "https://..." }`
  - Receives the Cloudinary image URL from the app.
  - Builds a prompt using the local ingredient dataset and the provided image URL.
  - Calls Google Gemini and returns analysis JSON.

- `POST /evaluate`
  - Request body: `{ "ingredients": ["Water", "Fragrance"] }` or `{ "raw_text": "Water, Fragrance" }`
  - Returns a simple conservative risk evaluation from the local dataset.

- `GET /ingredient-dataset`
  - Returns the small local ingredient dataset used by the backend.

- `POST /evaluate-rag`
  - Request body: `{ "ingredients": ["Water", "Fragrance"] }` or `{ "raw_text": "Water, Fragrance" }`
  - Uses the local dataset and Google Gemini to generate a dataset-backed analysis.

## Backend flow

1. App uploads the camera image to Cloudinary and receives a secure URL.
2. App sends `{ "image_url": "<cloudinary_url>" }` to backend `/analyze`.
3. Backend builds a prompt with the local ingredient dataset and the image URL.
4. Backend calls Google Gemini and parses the returned JSON.
5. Backend responds with `overall_risk`, `summary`, `ingredients`, and `image_url`.

## Local dataset

The backend includes a small dataset of common skincare ingredients in `ingredient_data.py`. This dataset is used to classify ingredients and to support RAG-style Gemini prompts.

## Notes

- The current `/analyze` endpoint expects the image URL only; it does not perform OCR locally.
- The app handles image upload to Cloudinary and passes the returned URL to the backend.
- If Gemini returns invalid JSON, the backend returns a 502 error.
