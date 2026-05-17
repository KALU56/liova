"""
clean_data.py  –  Cleans and ENRICHES the cosmetics dataset.

Enrichment adds per-ingredient safety level, effects, and skin guidance
into each product's clean_text so FAISS retrieval returns richer context.

Run from the backend/ directory:
    python src/clean_data.py
"""

import re
import sys
import os
import pandas as pd

# Allow imports from the backend root directory
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from ingredient_data import get_ingredient_info

# ─── Load ───────────────────────────────────────────────────────────────────
df = pd.read_csv("data/raw/cosmetics.csv")
df.columns = df.columns.str.strip().str.lower().str.replace(" ", "_")
print(f"Loaded {len(df)} rows. Columns: {list(df.columns)}")

# ─── Basic cleaning ──────────────────────────────────────────────────────────
df = df.dropna(subset=["ingredients"])
df = df.drop_duplicates()

SKIN_COLS = ["combination", "dry", "normal", "oily", "sensitive"]
TEXT_COLS = ["label", "brand", "name", "ingredients"]


def normalize_text(value: str) -> str:
    value = str(value).lower().strip()
    return re.sub(r"\s+", " ", value)


for col in TEXT_COLS:
    if col in df.columns:
        df[col] = df[col].apply(normalize_text)


# ─── Ingredient enrichment helpers ──────────────────────────────────────────

SAFETY_EMOJI = {"low": "✅", "medium": "⚠️", "high": "🚫", "unknown": "❓"}


def parse_ingredients(raw: str) -> list[str]:
    """Split ingredient string into individual ingredient names."""
    raw = re.sub(r"ingredients?\s*:\s*", "", raw.lower())
    parts = re.split(r"[,;]+", raw)
    result = []
    for p in parts:
        p = p.strip().rstrip(".")
        p = re.sub(r"\s+", " ", p)
        if len(p) >= 3:
            result.append(p)
    return result


def build_ingredient_summary(ingredient_name: str) -> str:
    """Return a one-line summary string for an ingredient."""
    info = get_ingredient_info(ingredient_name)
    emoji = SAFETY_EMOJI.get(info["safety"], "❓")
    parts = [f"{ingredient_name} [{info['safety'].upper()} {emoji}]"]
    if info["effect"] and info["effect"] != "no data":
        parts.append(f"effect: {info['effect']}")
    if info["good_for"]:
        parts.append(f"good for: {', '.join(info['good_for'])}")
    if info["avoid"]:
        parts.append(f"avoid if: {', '.join(info['avoid'])}")
    if info["note"] and info["note"] != "No specific data. Patch test recommended.":
        parts.append(f"note: {info['note']}")
    return " | ".join(parts)


def build_risk_flags(ingredients: list[str]) -> tuple[list[str], list[str], list[str]]:
    """Return (high_risk, medium_risk, safe) ingredient lists."""
    high, medium, safe = [], [], []
    for ing in ingredients:
        info = get_ingredient_info(ing)
        safety = info.get("safety", "unknown")
        if safety == "high":
            high.append(ing)
        elif safety == "medium":
            medium.append(ing)
        else:
            safe.append(ing)
    return high, medium, safe


def build_skin_warnings(ingredients: list[str]) -> dict[str, list[str]]:
    """Return dict of {skin_type: [ingredients to avoid for that skin type]}."""
    skin_warnings: dict[str, list[str]] = {}
    for ing in ingredients:
        info = get_ingredient_info(ing)
        for skin in info.get("avoid", []):
            skin_warnings.setdefault(skin, []).append(ing)
    return skin_warnings


def build_enriched_clean_text(row: pd.Series) -> str:
    """
    Build a rich text block for this product, including:
      - product metadata
      - per-ingredient safety + effect
      - overall risk summary
      - skin suitability from dataset flags
      - skin-type-specific warnings from ingredient KB
    """
    # 1. Parse ingredients
    raw_ingredients = str(row.get("ingredients", ""))
    ingredient_list = parse_ingredients(raw_ingredients)

    # 2. Per-ingredient summaries (limit to first 20 to keep text manageable)
    ing_summaries = [build_ingredient_summary(i) for i in ingredient_list[:20]]

    # 3. Risk flags
    high_risk, medium_risk, _ = build_risk_flags(ingredient_list)

    # 4. Skin warnings from KB
    skin_warnings = build_skin_warnings(ingredient_list)

    # 5. Dataset skin suitability flags
    skin_labels = []
    for col in SKIN_COLS:
        if col in row and str(row[col]).strip() in {"1", "1.0", "true"}:
            skin_labels.append(col)

    # 6. Overall risk level
    if high_risk:
        overall_risk = f"HIGH RISK 🚫 — contains: {', '.join(high_risk[:5])}"
    elif medium_risk:
        overall_risk = f"MODERATE RISK ⚠️ — caution with: {', '.join(medium_risk[:5])}"
    else:
        overall_risk = "LOW RISK ✅ — no major flagged ingredients"

    # 7. Assemble text
    lines = [
        f"Product: {row.get('name', 'unknown')}",
        f"Brand: {row.get('brand', 'unknown')}",
        f"Category: {row.get('label', 'unknown')}",
        f"Price: {row.get('price', 'N/A')} | Rating: {row.get('rank', 'N/A')}",
        f"Suitable for skin types: {', '.join(skin_labels) if skin_labels else 'not specified'}",
        f"Overall risk: {overall_risk}",
        "",
        "Ingredient analysis:",
    ]
    lines.extend(ing_summaries)

    if skin_warnings:
        lines.append("")
        lines.append("Skin-type specific warnings:")
        for skin, ings in skin_warnings.items():
            lines.append(f"  - {skin} skin: caution with {', '.join(ings[:4])}")

    return "\n".join(lines)


# ─── Apply enrichment ────────────────────────────────────────────────────────
print("Enriching dataset with ingredient-level safety data...")
df["clean_text"] = df.apply(build_enriched_clean_text, axis=1)
df["ingredients_clean"] = df["ingredients"].apply(
    lambda x: re.sub(r"[^a-z0-9,\-\s\(\)]", " ", x)
)

# ─── Save ────────────────────────────────────────────────────────────────────
os.makedirs("data/processed", exist_ok=True)
df.to_csv("data/processed/cleaned_dataset.csv", index=False)
print(f"✅ Enriched dataset saved → data/processed/cleaned_dataset.csv")
print(f"   Rows: {len(df)}")
print(f"\nSample clean_text for first product:\n")
print(df["clean_text"].iloc[0])
