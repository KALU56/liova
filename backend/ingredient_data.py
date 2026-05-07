# Fallback ingredient data - used only if CSV file is not found

FALLBACK_INGREDIENT_DATA = {
    "water": {
        "risk_level": "low",
        "explanation": "Water is a gentle base ingredient used for hydration."
    },
    "glycerin": {
        "risk_level": "low",
        "explanation": "Glycerin is a common moisturizer that is usually skin-friendly."
    },
    "niacinamide": {
        "risk_level": "low",
        "explanation": "Niacinamide is a mild vitamin ingredient for skin health."
    },
    "fragrance": {
        "risk_level": "medium",
        "explanation": "Fragrance can cause irritation for sensitive skin."
    },
    "alcohol": {
        "risk_level": "medium",
        "explanation": "Alcohol can be drying for sensitive and dry skin types."
    },
    "retinol": {
        "risk_level": "high",
        "explanation": "Retinol can cause irritation, especially for sensitive skin."
    },
    "oxybenzone": {
        "risk_level": "high",
        "explanation": "Chemical sunscreen ingredient linked to hormone concerns."
    },
    "formaldehyde": {
        "risk_level": "high",
        "explanation": "Known carcinogen - avoid this ingredient."
    }
}


def get_fallback_risk(ingredient_name: str) -> dict:
    name_lower = ingredient_name.lower()
    for key, value in FALLBACK_INGREDIENT_DATA.items():
        if key in name_lower or name_lower in key:
            return value
    return {
        "risk_level": "unknown",
        "explanation": "Limited data available. Patch test recommended."
    }