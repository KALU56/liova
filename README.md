# Liova – Cosmetic Ingredient AI Analyzer

**Liova** is a full-stack, AI-powered mobile application designed to help users understand the cosmetic products they use. By scanning a product label or pasting an ingredients list, users receive a highly personalized, research-backed skin risk summary powered by **Retrieval-Augmented Generation (RAG)**.

This repository contains the complete source code for the project, split into two main components: a **Flutter mobile app** and a **Python FastAPI backend**.

---

## 🏗️ Repository Structure

```text
/
├── li/             # Frontend: Flutter mobile application
└── backend/        # Backend: FastAPI server, FAISS Vector DB, and Data Pipeline
```

For deep technical dives into each component, refer to their specific documentation:
- 📖 [Backend Architecture & Data Pipeline Documentation](backend/README.md)
- 📖 [Frontend Architecture & UI Flow Documentation](li/README.md)

---

## 🧠 How the System Works (The Complete Data Flow)

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

## 📱 Frontend (Flutter) Highlights

The mobile application is built with **Flutter (Dart)** and follows a clean, service-oriented architecture.

- **Cross-Platform:** Runs seamlessly on iOS and Android.
- **Premium Aesthetics:** Features a modern design system (`AppTheme`) utilizing soft rose gradients, glassmorphism, and smooth micro-animations.
- **Real-Time Database:** Uses **Firebase Firestore** to stream the user's scan history to the Home and History pages reactively.
- **Camera Integration:** Utilizes `image_picker` for capturing product labels on the fly.
- **State Management:** Keeps UI logic separate from business logic via dedicated service classes (`ApiService`, `CloudinaryService`, `HistoryService`).

---

## ⚙️ Backend (FastAPI + AI) Highlights

The backend acts as the intelligent core of the application, orchestrating the complex RAG pipeline.

- **High-Performance Framework:** Built with **FastAPI** for asynchronous, ultra-fast API handling.
- **Data Enrichment Pipeline:** Raw cosmetic CSV datasets are ingested and enriched (`clean_data.py`) with a local knowledge base of safety warnings and skin-type suitability flags.
- **Hybrid Search Engine:** FAISS doesn't just do semantic search. `retrieve.py` implements a hybrid scoring formula combining:
  - Vector Similarity (65%)
  - Exact Ingredient Overlap (25%)
  - Skin Suitability Match (10%)
- **Self-Healing AI:** Implements fallback regex parsers (`_parse_json_object`) and prompt-repair mechanisms to ensure that if the AI hallucinates malformed JSON, the app never crashes.

---

## 🚀 Getting Started

To run the full Liova stack locally, you need to start both the backend server and the Flutter application.

### 1. Start the Backend
Navigate to the backend directory, install the Python dependencies, configure your API keys, and start the Uvicorn server:

```bash
cd backend
pip install -r requirements.txt

# Create a .env file with your Gemini API key
echo "GOOGLE_API_KEY=your_gemini_key_here" > .env
echo "GOOGLE_MODEL=gemini-2.5-flash" >> .env

# Run the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Start the Frontend
In a new terminal, navigate to the Flutter directory, fetch the Dart packages, and run the app on your emulator or connected device:

```bash
cd li
flutter pub get

# Setup your environment variables (Cloudinary API, etc.)
# Edit the existing li/.env file with your credentials

# Run the app
flutter run
```

---

*Project Liova – Empowering users with AI-driven, research-backed cosmetic transparency.*
