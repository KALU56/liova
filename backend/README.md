# Liova Backend Architecture & File Guide

The Liova backend is a powerful Python FastAPI service designed to provide advanced cosmetic ingredient analysis and product recommendation. It uses a Retrieval-Augmented Generation (RAG) architecture powered by a local Vector Database (FAISS), Sentence Transformers, and Google Gemini.

---

## 🗂️ Detailed File-by-File Breakdown

This section explains exactly what every single file in the backend does, why it exists, and how it fits into the overall system.

### 1. `main.py`
**Purpose:** The central nervous system of the backend. It is the FastAPI application server that receives HTTP requests from the Flutter app.
**Deep Dive:**
- **Endpoints:** Defines `/analyze-image`, `/analyze-text`, `/ask`, and `/health`.
- **RAG Orchestration:** When an image is uploaded, it calls Gemini Vision to extract ingredients, passes those ingredients to the `Retriever` to fetch similar products, and then calls Gemini *again* with the retrieved context to generate a highly accurate, dataset-backed analysis.
- **Self-Healing AI:** LLMs can be unpredictable. `main.py` includes robust helper functions (`_parse_json_object` and `_parse_or_repair_json`) that detect malformed or truncated JSON from Gemini, and automatically trigger fallback functions or secondary "repair" prompts to ensure the mobile app never crashes.

### 2. `src/clean_data.py`
**Purpose:** The Data ETL (Extract, Transform, Load) pipeline. It turns a generic dataset into a rich knowledge base.
**Deep Dive:**
- **Why it exists:** Raw datasets just list ingredients. For RAG to be effective, the AI needs *context*. 
- **What it does:** It reads the raw `data/raw/cosmetics.csv` dataset, drops missing values, and normalizes text. Then, it uses the knowledge from `ingredient_data.py` to synthesize a rich `clean_text` block for every single product. This block explicitly states the overall risk level (e.g., "HIGH RISK 🚫"), specific skin-type warnings, and individual ingredient safety levels. 
- **Output:** It saves this highly enriched dataset to `data/processed/cleaned_dataset.csv`, which becomes the foundation for vectorization.

### 3. `src/create_embeddings.py`
**Purpose:** The Vectorizer. It converts human-readable text into mathematics for rapid semantic searching.
**Deep Dive:**
- **Why it exists:** AI needs a fast way to find similar products without reading millions of words.
- **What it does:** It loads the `cleaned_dataset.csv` and uses the HuggingFace `SentenceTransformer` (`all-MiniLM-L6-v2`) to encode every `clean_text` block into a 384-dimensional dense vector. 
- **Indexing:** It feeds these vectors into a **FAISS** (Facebook AI Similarity Search) `IndexFlatL2` index. FAISS organizes these vectors in memory so that searching through them takes milliseconds.
- **Output:** It saves the FAISS index (`faiss_index.bin`) and the raw texts (`texts.pkl`) into the `models/` folder so the FastAPI server can load them instantly on startup.

### 4. `src/retrieve.py`
**Purpose:** The Search Engine. It takes user input and finds the most relevant products from the FAISS database.
**Deep Dive:**
- **Why it exists:** Simple vector search (semantic similarity) isn't enough for chemistry and cosmetics; we need exact matches too.
- **What it does:** Defines the `Retriever` class loaded by `main.py`. When a search is performed, it executes a **Hybrid Search**:
  1. **Semantic Search (65%):** Uses FAISS to find products conceptually similar to the user's query.
  2. **Keyword Overlap (25%):** Extracts specific ingredients from the user's query and gives bonus points to database products that contain those *exact* same ingredients.
  3. **Skin Suitability (10%):** Infers the user's skin type from the query and boosts products that historically perform well for that skin type.
- **Output:** Returns a reranked list of highly relevant contexts to feed into the Gemini LLM.

### 5. `ingredient_data.py`
**Purpose:** The Static Knowledge Base. A hardcoded dictionary of common cosmetic ingredients.
**Deep Dive:**
- **Why it exists:** LLMs can hallucinate safety data. We need a grounded source of truth for known irritants.
- **What it does:** Maps specific ingredients (like "Salicylic Acid" or "Fragrance") to their safety levels (safe/medium/high risk), their main effects, and which skin types should use or avoid them. 
- **How it's used:** `clean_data.py` imports this file to inject these explicit warnings into the dataset before it gets vectorized.

### 6. `download_data.py`
**Purpose:** An initialization script to fetch the raw data.
**Deep Dive:**
- **Why it exists:** Datasets are too large to store directly in Git repositories.
- **What it does:** Uses the `kagglehub` package to programmatically download the "cosmetics-datasets" directly from Kaggle into the local machine. It ensures any developer can quickly bootstrap the project without manually searching for CSV files online.

### 7. `.env` and `requirements.txt`
**Purpose:** Configuration and dependencies.
**Deep Dive:**
- **`requirements.txt`:** Lists all the Python libraries required (FastAPI, Uvicorn, FAISS, SentenceTransformers, Pandas, etc.) to ensure the environment is reproducible.
- **`.env`:** A hidden file that stores your secret `GOOGLE_API_KEY` and the specific model string (`GOOGLE_MODEL`). `main.py` reads this to authenticate with Google's servers.

### 8. Frontend Integration (Flutter Connection)
**Purpose:** How this backend communicates with the Flutter mobile application.
**Deep Dive:**
- **The Bridge:** The entire connection between the mobile app and this backend is handled by the **FastAPI endpoints** defined in `main.py` (`/analyze-image` and `/analyze-text`).
- **Flutter Side (`li/lib/services/api_service.dart`):** In the Flutter app, the `ApiService` class contains the HTTP logic that connects to this backend. It automatically formats the data into JSON and POSTs it to the FastAPI server.
- **Image Upload vs. Analysis Pipeline:** 
  It is important to understand the dual-path image flow:
  1. **Cloudinary (Storage):** The Flutter app uploads the photo to Cloudinary *only* to get a public URL for displaying the thumbnail in the user's history later.
  2. **FastAPI (Analysis):** Cloudinary is **not** used for the actual AI analysis. Instead, the Flutter app takes the raw image bytes, converts them to a Base64 string, and sends that Base64 string directly to the FastAPI backend at `http://10.0.2.2:8000/analyze-image`.
- **Image-to-Text Analysis (Gemini Vision):**
  1. Once `main.py` receives the Base64 image, it passes it directly to **Google Gemini Vision** (`call_gemini_with_image`).
  2. Gemini Vision acts as an advanced OCR (Optical Character Recognition) tool. It "reads" the physical cosmetic label from the photo and extracts a JSON array of raw ingredient names.
  3. The backend takes this freshly extracted text array, feeds it into the FAISS `Retriever` to find similar products in the database, and finally passes the retrieved context to the Gemini Text model to generate the final skin risk summary.
  4. The generated JSON is sent back to the Flutter app and parsed into a `ScanResult` Dart object to be rendered on screen.

---

## 🚀 How to Run the Pipeline

If you want to recreate the vector database from scratch (for example, if you add new ingredients to `ingredient_data.py`):

1. **Clean Data:** `python src/clean_data.py` (Generates the enriched dataset)
2. **Vectorize:** `python src/create_embeddings.py` (Generates the FAISS index)
3. **Start Server:** `uvicorn main:app --host 0.0.0.0 --port 8000 --reload` (Starts the FastAPI app)
