import pandas as pd
import re
import os
from typing import List, Dict, Optional

_ingredient_dataset = None


def load_ingredient_dataset():
    global _ingredient_dataset
    
    if _ingredient_dataset is not None:
        return _ingredient_dataset
    
    possible_paths = [
        'data/cosmetics_dataset.csv',
        'data/cosmetics.csv',
        'cosmetics_dataset.csv',
        'cosmetics-data.csv',
        '../data/cosmetics_dataset.csv'
    ]
    
    # Also look for any CSV file in data folder
    if os.path.exists('data'):
        for file in os.listdir('data'):
            if file.endswith('.csv'):
                possible_paths.insert(0, f'data/{file}')
    
    for path in possible_paths:
        if os.path.exists(path):
            try:
                df = pd.read_csv(path)
                print(f"✅ Loaded dataset: {path} ({len(df)} rows)")
                print(f"   Columns: {df.columns.tolist()}")
                _ingredient_dataset = df
                return _ingredient_dataset
            except Exception as e:
                print(f"Error loading {path}: {e}")
    
    print("⚠️ No dataset file found! Using fallback data.")
    _ingredient_dataset = None
    return None


def find_ingredient_risk(ingredient_name: str) -> Optional[Dict]:
    df = load_ingredient_dataset()
    
    if df is None:
        return None
    
    ingredient_lower = ingredient_name.lower().strip()
    
    # Try to find name column
    name_col = None
    for col in df.columns:
        if col.lower() in ['label', 'ingredient', 'name', 'ingredients', 'inci']:
            name_col = col
            break
    
    if name_col is None:
        name_col = df.columns[0]
    
    # Try to find risk column
    risk_col = None
    for col in df.columns:
        if col.lower() in ['risk', 'safety', 'hazard', 'ewg', 'rating', 'risk_level']:
            risk_col = col
            break
    
    # Search for ingredient
    for idx, row in df.iterrows():
        db_name = str(row[name_col]).lower()
        if ingredient_lower in db_name or db_name in ingredient_lower:
            result = {
                'name': row[name_col],
                'risk_level': 'medium',
                'explanation': 'No detailed information available.'
            }
            
            if risk_col:
                risk_value = str(row[risk_col]).lower()
                if 'low' in risk_value or 'safe' in risk_value:
                    result['risk_level'] = 'low'
                elif 'high' in risk_value or 'danger' in risk_value or 'harmful' in risk_value:
                    result['risk_level'] = 'high'
                elif 'medium' in risk_value:
                    result['risk_level'] = 'medium'
            
            return result
    
    return None


def parse_ingredient_list(text: str) -> List[str]:
    if not text:
        return []
    
    text = text.lower()
    
    markers = ["ingredients:", "ingrédients:", "ingredienti:"]
    ingredients_text = text
    
    for marker in markers:
        if marker in text:
            ingredients_text = text.split(marker)[-1]
            break
    
    ingredients_text = re.sub(r'[\(\)\[\]\{\}]', ' ', ingredients_text)
    parts = re.split(r'[,\n;•·]', ingredients_text)
    
    ingredients = []
    skip_words = {'and', 'with', 'may', 'contain', 'contains', 'less', 'than'}
    
    for part in parts:
        cleaned = part.strip()
        if cleaned and len(cleaned) > 2 and cleaned not in skip_words:
            cleaned = re.sub(r'\(\d+%\)', '', cleaned).strip()
            if cleaned:
                ingredients.append(cleaned[:60])
    
    seen = set()
    unique = []
    for ing in ingredients:
        if ing not in seen:
            seen.add(ing)
            unique.append(ing)
    
    return unique[:25]


def classify_ingredients(ingredients: List[str]) -> List[Dict]:
    results = []
    
    for name in ingredients:
        dataset_result = find_ingredient_risk(name)
        
        if dataset_result:
            results.append({
                'name': name,
                'risk_level': dataset_result['risk_level'],
                'explanation': dataset_result['explanation']
            })
        else:
            results.append({
                'name': name,
                'risk_level': 'unknown',
                'explanation': 'Limited safety data available. Patch test recommended.'
            })
    
    return results


def compute_overall_risk(classified_ingredients: List[Dict]) -> str:
    for item in classified_ingredients:
        if item['risk_level'] == 'high':
            return 'high'
    for item in classified_ingredients:
        if item['risk_level'] == 'medium' or item['risk_level'] == 'unknown':
            return 'medium'
    return 'low'