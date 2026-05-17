# Liova Backend Architecture & Exhaustive File Guide

The Liova backend is a highly specialized Python FastAPI service built to act as the intelligent core of the Liova mobile application. Its primary responsibility is to receive raw data from the mobile app (such as pictures of cosmetic labels) and return a highly accurate, scientifically-backed analysis of the ingredients. 

To achieve this without suffering from AI hallucinations (where an AI invents fake facts), this backend utilizes an advanced **Retrieval-Augmented Generation (RAG)** architecture. This means the system combines the reasoning power of a Large Language Model (Google Gemini) with the factual certainty of a local Vector Database (FAISS).

---

## 🗂️ Exhaustive File-by-File Breakdown

This section breaks down the exact purpose, mechanics, and inner workings of every single file within the backend infrastructure. It explains *why* the file was created, *how* it operates under the hood, and what its exact outputs are.

### 1. `main.py`
**The Purpose:** This is the central nervous system of the entire backend. It acts as the traffic controller, receiving HTTP requests from the mobile app, passing data to the AI, and sending the final results back.
**How it Works in Detail:**
- **The Endpoints:** It uses the FastAPI framework to open specific web addresses (endpoints) like `/analyze-image`. When the mobile app sends data here, `main.py` wakes up to process it.
- **The Orchestration Flow:** 
  1. The file receives a Base64 encoded image string from the user. 
  2. It immediately calls `call_gemini_with_image()`, which uses Google Gemini Vision to perform Optical Character Recognition (OCR). This step looks at the physical photo and extracts the English text of the ingredients on the label.
  3. Once it has the text, `main.py` calls the `Retriever` class (from `retrieve.py`). The Retriever searches the local database and returns a list of verified facts and safety warnings about those specific ingredients.
  4. Finally, `main.py` takes the extracted ingredients AND the verified facts, and sends them *back* to Google Gemini with a massive prompt. The prompt forces Gemini to only use the provided facts to write the final skin risk analysis.
- **Why the 'Self-Healing' functions exist:** Large Language Models are unpredictable and sometimes generate broken formatting. `main.py` contains `_parse_json_object` and `_parse_or_repair_json`. If Gemini returns a broken response, these functions use complex Regular Expressions (Regex) to manually extract the data, or they force a fallback system, guaranteeing the mobile app never crashes from bad data.

### 2. `src/clean_data.py`
**The Purpose:** This is the Data ETL (Extract, Transform, Load) pipeline. Its job is to take a boring, generic list of cosmetic products and turn it into a highly descriptive, rich knowledge base that the AI can actually understand.
**How it Works in Detail:**
- **Why we need it:** If we just gave the AI a spreadsheet with columns like "Product Name" and "Ingredients", the AI wouldn't understand the safety risks. It needs context.
- **The Mechanics:** 
  1. The script opens `data/raw/cosmetics.csv` using the Pandas library.
  2. It cleans the data by dropping missing values and forcing all text to lowercase to prevent duplicates.
  3. It then opens our expert database (`ingredient_kb.json`) and cross-references every single ingredient in the CSV against our expert safety rules.
  4. It synthesizes a massive `clean_text` paragraph for every product. Instead of just listing "Water, Fragrance", the `clean_text` will literally say: *"HIGH RISK 🚫 — caution with: fragrance. Skin-type specific warnings: sensitive skin: caution with fragrance."*
- **The Result:** It outputs `data/processed/cleaned_dataset.csv`. This new file contains all the rich, explicit safety warnings seamlessly integrated into the text, which is exactly what the AI needs to read to understand a product's danger level.

### 3. `src/create_embeddings.py`
**The Purpose:** The Vectorizer. It converts human-readable English text into pure mathematics so a computer can search it in milliseconds.
**How it Works in Detail:**
- **Why we need it:** When a user scans a product, we need to find similar products in our database instantly. Reading millions of words takes too long. By converting words to numbers, we can use math to find similarities instantly.
- **The Mechanics:** 
  1. It loads the rich `cleaned_dataset.csv` we created in the previous step.
  2. It loads a HuggingFace Neural Network model called `SentenceTransformer('all-MiniLM-L6-v2')`.
  3. It passes every single `clean_text` paragraph through this neural network. The network outputs a 384-dimensional mathematical vector (a list of 384 numbers) that represents the "meaning" of that paragraph.
  4. It takes all of these vectors and builds a **FAISS** (Facebook AI Similarity Search) index. FAISS is an incredibly advanced search engine built specifically for these vectors.
- **The Result:** It creates `models/faiss_index.bin` (the mathematical search index) and `models/texts.pkl` (the actual English text). These files are saved to the hard drive so `main.py` can load them instantly when the server starts.

### 4. `src/retrieve.py`
**The Purpose:** The Advanced Search Engine. When the user asks a question or scans a product, this file calculates exactly which facts from the database are the most important to return.
**How it Works in Detail:**
- **Why we need it:** Standard vector search only looks for conceptual similarity (e.g., matching "moisturizer" with "lotion"). But in cosmetics, chemistry matters. We need exact ingredient matches, not just conceptual matches.
- **The Mechanics:** It implements a **Hybrid Search Algorithm**. When `main.py` asks it to search for something, it calculates three completely different scores for every product in the database:
  1. **Semantic Score (65% Weight):** It queries the FAISS index to find products whose vectors mathematically point in the same direction as the user's query.
  2. **Overlap Score (25% Weight):** It uses Regular Expressions to chop the user's input into individual ingredients. It then counts exactly how many of those specific ingredients appear in the database products.
  3. **Skin Suitability Score (10% Weight):** It infers the user's skin type (e.g., "oily") and checks if the database product actually has a historical track record of being good for oily skin.
- **The Result:** It merges these three scores into one final number, sorts the database by that number, and returns the top 5 most relevant, scientifically accurate facts to be fed into Gemini.

### 5. `ingredient_data.py` & `data/raw/ingredient_kb.json`
**The Purpose:** The Expert Knowledge Base. This is the absolute source of truth regarding what ingredients are toxic, safe, or irritating.
**How it Works in Detail:**
- **Why we need it:** We cannot trust Google Gemini to just "guess" if an ingredient is safe. Gemini might say Fragrance is fine, when in reality it causes severe allergic reactions for sensitive skin. We must force the AI to obey a strict set of rules.
- **The Mechanics:** `ingredient_kb.json` is a massive JSON data file containing hundreds of cosmetic ingredients. For every ingredient, it strictly defines its safety level ("low", "medium", "high"), its physical effects (e.g., "humectant"), and the exact skin types that should use or avoid it.
- **The Connection:** `ingredient_data.py` is a lightweight Python script that opens this JSON file, loads it into the server's RAM, and provides helper functions like `get_ingredient_info()` so that `clean_data.py` can easily access the rules while it's building the database.

### 6. `download_data.py`
**The Purpose:** The Bootstrap Script. It automates the process of fetching the raw CSV data from the internet.
**How it Works in Detail:**
- **Why we need it:** Machine learning datasets are massive. If we uploaded the raw CSV files directly to GitHub, the repository would be too large and slow to download.
- **The Mechanics:** It uses a Python library called `kagglehub` to securely connect to Kaggle's servers. It programmatically downloads the "cosmetics-datasets" directly into the developer's local `/data/raw` folder. This ensures that anyone who downloads the code can instantly fetch the data without having to create Kaggle accounts or click download buttons online.

### 7. `.env` and `requirements.txt`
**The Purpose:** System Configuration.
**How it Works in Detail:**
- **`requirements.txt`:** This file contains a strict list of every single third-party Python library (like FastAPI, Uvicorn, Pandas, FAISS, etc.) needed to make the code run. Running `pip install -r requirements.txt` forces the computer to download the exact correct versions of these libraries so the code doesn't crash.
- **`.env`:** This is a hidden security file. It stores highly sensitive passwords, like the `GOOGLE_API_KEY`. By keeping this key in `.env` (which is blocked from being uploaded to GitHub via `.gitignore`), hackers cannot steal the API key and run up a massive Google Cloud bill. `main.py` securely reads this file when it boots up.

---

## 🧠 The Complete Data Flow

Liova avoids AI hallucinations by using a **RAG (Retrieval-Augmented Generation)** architecture. Here is the exact step-by-step flow from the moment a user scans a product to the final result:

### **Phase 1: The User Input (Frontend)**
1. **The Capture:** The user opens the Liova Flutter app, goes to the Scan Page, selects their skin type (e.g., "Sensitive"), and takes a photo of a cosmetic product's ingredient label using their camera.
2. **The Split:** The Flutter app takes that photo and does two things simultaneously:
   - **Storage Flow:** It uploads the photo to Cloudinary. Cloudinary saves it and returns a URL. *(Note: This URL is ONLY used so the app can display a tiny thumbnail picture in the user's history page later).*
   - **Analysis Flow:** It converts the raw photo into a `Base64` text string. It then packages this Base64 string, along with the "Sensitive" skin type, and sends it directly to the FastAPI backend via HTTP POST.

### **Phase 2: Text Extraction (Backend)**
3. **The AI Eyes (OCR):** The FastAPI backend receives the Base64 image. It immediately forwards the image to **Google Gemini Vision**.
4. **Reading the Label:** Gemini Vision acts as a smart set of eyes. It reads the physical text off the bottle in the photo, ignores the marketing text, and perfectly extracts just the ingredients into a raw list (e.g., `["Water", "Glycerin", "Fragrance"]`).

### **Phase 3: The Brain & Database (Backend)**
5. **The Search Engine:** The backend takes that extracted list of ingredients and feeds it into the FAISS `Retriever`. 
6. **Vector Matching:** The `Retriever` rapidly searches the local vector database (built using `ingredient_kb.json` and `cosmetics.csv`). It looks for exact ingredient matches and pulls up verified scientific facts, safety warnings, and historical data about how those ingredients react with the user's specific skin type.
7. **Building the Context:** The backend gathers all of this verified database research and packages it into a strict "Context" document.

### **Phase 4: The Final Analysis (Backend)**
8. **The Prompt:** The backend sends a final massive prompt back to the **Google Gemini Text Model**. It essentially says: *"The user has Sensitive skin. The product contains Water, Glycerin, and Fragrance. Here is verified database research proving Fragrance is bad for Sensitive skin. Based strictly on this research, generate a JSON skin risk analysis."*
9. **The Output:** Gemini generates a perfectly formatted JSON response containing the overall risk level, a suitability score out of 10, and specific bullet points explaining what is good and bad about the product.
10. **The Return:** The FastAPI backend sends this JSON analysis back over the internet to the Flutter app.

### **Phase 5: The Result (Frontend)**
11. **The Display:** The Flutter app receives the JSON, parses it, and beautifully renders the Results Screen—showing the score and highlighting dangerous ingredients in red.
12. **The Save:** Behind the scenes, the Flutter app combines the final Analysis JSON with the Cloudinary `imageUrl` it got in Step 2, and saves the whole package permanently into **Firebase Firestore**.
13. **The History:** The next time the user opens the History Page, the app streams that data from Firebase and displays the scan exactly as it was, complete with the little photo thumbnail!

---

## 🚀 How to Run the Pipeline

If you want to recreate the vector database from scratch (for example, if you add new ingredients to `ingredient_kb.json`):

1. **Clean Data:** `python src/clean_data.py` (Generates the enriched dataset)
2. **Vectorize:** `python src/create_embeddings.py` (Generates the FAISS index)
3. **Start Server:** `uvicorn main:app --host 0.0.0.0 --port 8000 --reload` (Starts the FastAPI app)
