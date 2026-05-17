import json
import os

"""
Ingredient knowledge base loader.
Loads safety level, effects, and skin type guidance from a JSON file.
safety: low | medium | high
"""

KB_FILE_PATH = os.path.join(os.path.dirname(__file__), "data", "raw", "ingredient_kb.json")

def _load_kb() -> dict:
    try:
        with open(KB_FILE_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"Warning: Could not load ingredient knowledge base from {KB_FILE_PATH}. Error: {e}")
        return {}

INGREDIENT_KB = _load_kb()

def get_ingredient_info(ingredient_name: str) -> dict:
    """
    Look up ingredient info by name (partial match supported).
    Returns a dict with safety, effect, good_for, avoid, note.
    """
    name_lower = ingredient_name.lower().strip()

    # Exact match
    if name_lower in INGREDIENT_KB:
        return INGREDIENT_KB[name_lower]

    # Partial match
    for key, value in INGREDIENT_KB.items():
        if key in name_lower or name_lower in key:
            return value

    return {
        "safety": "unknown",
        "effect": "no data",
        "good_for": [],
        "avoid": [],
        "note": "No specific data. Patch test recommended."
    }

# Keep old function for backward compatibility
def get_fallback_risk(ingredient_name: str) -> dict:
    info = get_ingredient_info(ingredient_name)
    return {"risk_level": info["safety"], "explanation": info["note"]}