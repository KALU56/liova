import pandas as pd
from sentence_transformers import SentenceTransformer
import numpy as np
import faiss
import pickle

# Load cleaned data
df = pd.read_csv("data/processed/cleaned_dataset.csv")

# Load model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Convert text to list
texts = df['clean_text'].tolist()
records = df.to_dict(orient="records")

print("Creating embeddings...")

# Create embeddings
embeddings = model.encode(texts)

# Convert to numpy array
embeddings = np.array(embeddings)

# Create FAISS index
dimension = embeddings.shape[1]
index = faiss.IndexFlatL2(dimension)

# Add embeddings
index.add(embeddings)

# Save FAISS index
faiss.write_index(index, "models/faiss_index.bin")

# Save texts (important for retrieval)
with open("models/texts.pkl", "wb") as f:
    pickle.dump(texts, f)

# Save full records (important for reranking/structured response)
with open("models/records.pkl", "wb") as f:
    pickle.dump(records, f)

print("✅ Embeddings + FAISS index created!")
