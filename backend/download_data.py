import subprocess
import sys

# Install kagglehub if not installed
subprocess.check_call([sys.executable, "-m", "pip", "install", "kagglehub"])

import kagglehub
import os

print("Downloading dataset...")
path = kagglehub.dataset_download("kingabzpro/cosmetics-datasets")

print(f"\nDataset location: {path}")
print("\nFiles found:")
for file in os.listdir(path):
    print(f"  - {file}")
    if file.endswith('.csv'):
        print(f"    ✅ This is a CSV file!")