# **Liova – Cosmetic Health Risk AI MVP Specification Document**

## **1. Project Overview**

**Purpose:**
Develop an AI system named **Liova** that allows users to scan or input cosmetic product information and receive a **research-backed skin risk summary** based on the product’s ingredients. The first version (MVP) will use **RAG (Retrieval-Augmented Generation)** to provide accurate outputs without fine-tuning.

**Scope:**

* Input: Product label scan or typed description
* Processing: Extract ingredients → retrieve research-backed facts → summarize with LLM
* Output: Skin risk summary for each ingredient + overall risk classification
* Platform: Web / mobile frontend connected to backend API

**Goals for MVP:**

1. Research-backed AI output using RAG
2. Functional frontend and backend pipeline
3. Ability to update knowledge base with new research anytime

---

## **2. Functional Requirements**

| Function                  | Description                                            | Input                          | Output                                                |
| ------------------------- | ------------------------------------------------------ | ------------------------------ | ----------------------------------------------------- |
| Ingredient Extraction     | Parse product scan or text to identify all ingredients | Product label (scan or text)   | List of normalized ingredients                        |
| Knowledge Retrieval (RAG) | Search knowledge base for facts about each ingredient  | List of ingredients            | Top-K relevant chunks with research facts             |
| LLM Summarization         | Generate skin risk summary from retrieved facts        | Ingredients + retrieved chunks | Readable summary per ingredient + overall risk        |
| API Endpoint              | Expose AI service to frontend/mobile app               | POST request with product data | JSON summary of skin risks                            |
| Frontend / Mobile         | Display AI summary to user                             | JSON response                  | Visual summary with risk highlights (low/medium/high) |

---

## **3. Non-Functional Requirements**

* **Performance:** Response time <5 seconds per query for 10–20 ingredients
* **Scalability:** Knowledge base can be expanded to hundreds/thousands of ingredients
* **Reliability:** AI outputs based on research sources, not hallucinations
* **Usability:** Simple, user-friendly interface for scanning or typing products
* **Maintainability:** Knowledge base updateable without retraining LLM

---

## **4. System Architecture**

**Modules:**

1. **RAG Knowledge Base (Separate Module)**

   * Stores embeddings of research chunks (PDFs, books, YouTube transcripts, websites)
   * Vector DB (FAISS / Pinecone / Weaviate)
   * Returns top-K facts relevant to user query

2. **LLM Module**

   * Pre-trained LLM (OpenAI GPT / HuggingFace)
   * Receives ingredient list + retrieved facts
   * Generates readable risk summary

3. **Backend (API Layer)**

   * FastAPI endpoint `/analyze-product`
   * Orchestrates: ingredient extraction → RAG retrieval → LLM summarization → JSON response
   * Handles multiple concurrent requests

4. **Frontend / Mobile App**

   * Input: scan or typed product
   * Output: highlighted summary of risks
   * Optional: color-coded risk levels

**Data Flow Diagram:**

```
User Input (scan / text)
        ↓
  Backend API (/analyze-product)
        ↓
   RAG Knowledge Base (vector DB)
        ↓
      LLM (generate summary)
        ↓
Backend returns JSON → Frontend displays
```

---

## **5. Data Preparation / Knowledge Base Feeding**

1. **Collect Sources:** PDFs, research papers, books, YouTube transcripts, FDA/EWG websites
2. **Extract Text:** Python libraries (`PyPDF2`, `pdfplumber`, `youtube-transcript-api`, `BeautifulSoup`)
3. **Chunk Text:** 100–500 words per chunk
4. **Normalize Ingredient Names:** Include synonyms (e.g., Salicylic Acid = BHA)
5. **Create Embeddings:** OpenAI `text-embedding-ada-002` or Sentence-BERT
6. **Store in Vector DB:** Include metadata (ingredient name, source, risk level, notes)
7. **Query:** Convert ingredient input → embeddings → retrieve top-K chunks → feed to LLM

---

## **6. MVP Roadmap (4–5 Weeks)**

| Week | Tasks                                                         | Deliverables                                                  |
| ---- | ------------------------------------------------------------- | ------------------------------------------------------------- |
| 1    | Collect research sources, extract text, normalize ingredients | Prepared research chunks for RAG                              |
| 2    | Create embeddings, store in vector DB                         | Functional knowledge base                                     |
| 3    | Build backend API with LLM integration                        | `/analyze-product` endpoint working                           |
| 4    | Frontend / Mobile interface                                   | User can scan or type product → see risk summary              |
| 5    | Testing & Publish                                             | MVP deployed, tested with real products, ready for beta users |

---

## **7. Optional Enhancements (Future Phases)**

1. **Fine-Tuning:** Cosmetic-specific dataset for consistent phrasing
2. **OCR for real-time label scanning**
3. **Multi-language support**
4. **Expanded knowledge base to thousands of ingredients**
5. **Advanced UX features:** search, filter, product history, alternatives

---

## **8. Tools / Technologies**

* **OCR / Text Extraction:** Tesseract, EasyOCR, YouTube transcript API
* **Backend / API:** Python, FastAPI
* **LLM:** OpenAI GPT / HuggingFace
* **RAG / Vector DB:** FAISS, Pinecone, Weaviate
* **Frontend / Mobile:** React / React Native / Expo
* **Database:** PostgreSQL / MongoDB

---

**Project Name:** **Liova** – First functional version focused on **RAG + LLM integration**, ready for MVP testing and deployment.
