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

## 🧠 How the System Works (Data Flow)

Liova avoids AI hallucinations by using a **RAG (Retrieval-Augmented Generation)** architecture. Instead of relying purely on a pre-trained model's memory, the system dynamically retrieves factual cosmetics data from a local vector database before generating an answer.

1. **User Input:** The user takes a picture of a skincare product label via the Flutter app.
2. **Cloud Storage:** The app uploads the raw image directly to **Cloudinary** and retrieves a secure public URL.
3. **API Request:** The app sends the image Base64 data (or Cloudinary URL) and the user's skin type to the FastAPI backend.
4. **AI Vision Extraction:** The backend uses **Google Gemini Vision** to extract the raw text/ingredients from the image.
5. **Vector Retrieval (FAISS):** The extracted ingredients are embedded into a dense vector space using `SentenceTransformers`. The backend queries a local **FAISS Vector Database** to find the most scientifically relevant products, safety warnings, and skin-type matches.
6. **LLM Synthesis:** The backend feeds the user's skin type, the raw ingredients, and the highly relevant FAISS context into **Google Gemini**. Gemini synthesizes a beautifully formatted, factual, and personalized JSON response.
7. **Display & History:** The Flutter app displays the results (highlighting safe/moderate/high-risk ingredients) and saves the analysis permanently to **Firebase Firestore**.

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
