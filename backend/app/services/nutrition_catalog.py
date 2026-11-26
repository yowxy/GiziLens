"""Food nutrition catalog ported from the Flutter client.

Provides per-100g nutrition values and a default portion size for a detected
class name, mirroring ``food_nutrition_catalog.dart``.
"""
from __future__ import annotations

from dataclasses import dataclass

# (category, default_gram, cal, protein, fat, carb, fiber) per 100 g
_OVERRIDES: dict[str, tuple[str, int, float, float, float, float, float]] = {
    "nasi_putih": ("Pokok", 200, 175, 3.2, 0.3, 40.6, 0.4),
    "nasi_merah": ("Pokok", 200, 149, 2.8, 0.4, 32.5, 1.8),
    "nasi_kuning": ("Pokok", 200, 180, 3.0, 3.0, 34.0, 0.8),
    "nasi_goreng": ("Pokok", 200, 193, 6.0, 6.0, 29.0, 1.2),
    "mie_goreng": ("Pokok", 180, 175, 5.0, 5.5, 27.0, 1.5),
    "bihun": ("Pokok", 180, 109, 0.9, 0.2, 25.0, 0.9),
    "kentang_rebus": ("Pokok", 150, 87, 1.9, 0.1, 20.1, 1.8),
    "roti_tawar": ("Pokok", 60, 248, 8.0, 3.2, 49.0, 2.7),
    "ayam_goreng": ("Lauk", 80, 260, 25.0, 17.0, 0, 0),
    "ayam_rebus": ("Lauk", 80, 165, 31.0, 3.6, 0, 0),
    "ayam_bakar": ("Lauk", 80, 215, 27.0, 10.0, 2.0, 0),
    "daging_sapi": ("Lauk", 75, 217, 26.1, 11.8, 0, 0),
    "ikan_goreng": ("Lauk", 75, 206, 22.0, 12.0, 0, 0),
    "ikan_bakar": ("Lauk", 75, 160, 25.0, 6.0, 0, 0),
    "telur_rebus": ("Lauk", 60, 154, 12.4, 10.8, 0.7, 0),
    "telur_dadar": ("Lauk", 60, 196, 11.0, 16.0, 1.5, 0),
    "tempe_goreng": ("Lauk", 100, 201, 19.9, 8.8, 13.5, 1.4),
    "tahu_goreng": ("Lauk", 80, 271, 17.2, 20.0, 8.9, 0.9),
    "udang": ("Lauk", 75, 99, 20.3, 1.1, 0.2, 0),
    "sayur_lain": ("Sayur", 75, 35, 2.0, 0.4, 6.0, 2.5),
    "bayam": ("Sayur", 75, 23, 2.9, 0.4, 3.6, 2.2),
    "wortel": ("Sayur", 75, 41, 0.9, 0.2, 9.6, 2.8),
    "tomat": ("Sayur", 75, 18, 0.9, 0.2, 3.9, 1.2),
    "tumis_kangkung": ("Sayur", 100, 72, 2.6, 4.5, 6.0, 2.0),
    "pisang": ("Buah", 100, 89, 1.1, 0.3, 22.8, 2.6),
    "jeruk": ("Buah", 120, 47, 0.9, 0.1, 11.8, 2.4),
    "apel": ("Buah", 100, 52, 0.3, 0.2, 13.8, 2.4),
    "pepaya": ("Buah", 100, 43, 0.5, 0.3, 10.8, 1.7),
    "mangga": ("Buah", 100, 60, 0.8, 0.4, 15.0, 1.6),
    "susu_kotak": ("Susu", 115, 61, 3.2, 3.3, 4.8, 0),
    "susu_coklat": ("Susu", 115, 78, 3.2, 2.5, 10.5, 0.5),
    "susu_kedelai": ("Susu", 115, 54, 3.3, 1.8, 6.3, 0.6),
    "yogurt": ("Susu", 100, 61, 3.5, 3.3, 4.7, 0),
}

_POKOK_PREFIXES = (
    "nasi", "mie", "bihun", "kwetiau", "makaroni", "kentang", "ubi", "singkong",
    "jagung", "talas", "roti", "oatmeal", "papeda", "lemper", "arem_arem",
    "getuk", "tiwul",
)
_SAYUR_PREFIXES = (
    "sayur", "tumis", "urap", "pecel", "gado", "karedok", "salad", "lalapan",
    "wortel", "tomat", "timun", "selada", "kol", "bayam", "kangkung", "sawi",
    "pakcoy", "buncis", "tauge", "labu", "terong", "jamur", "paprika", "pare",
    "gambas", "okra", "rebung", "daun", "kemangi", "seledri", "lobak", "bit",
    "garlic",
)
_BUAH_PREFIXES = (
    "pisang", "jeruk", "apel", "pepaya", "semangka", "melon", "salak", "mangga",
    "nanas", "jambu", "anggur", "pir", "alpukat", "buah", "kiwi", "stroberi",
    "belimbing", "manggis", "rambutan", "lengkeng", "durian", "nangka",
    "cempedak", "sirsak", "markisa", "duku", "sawo", "kedondong", "delima",
    "blewah", "lemon", "kurma", "blueberry", "kelapa", "leci", "ceri",
)
_SUSU_PREFIXES = (
    "susu", "yogurt", "keju", "kefir", "dadih", "dangke", "puding_susu", "es_krim",
)
_NABATI_PREFIXES = (
    "tempe", "tahu", "oncom", "kacang", "edamame", "perkedel", "bakwan",
)
_PELENGKAP_PREFIXES = (
    "sambal", "acar", "saus", "kecap", "kerupuk", "emping", "keripik",
    "rempeyek", "bawang_goreng", "cabai", "pelengkap",
)
_CAMILAN_PREFIXES = (
    "kue", "bolu", "biskuit", "pisang_goreng", "lumpia", "risoles", "pastel",
    "klepon", "onde", "burger",
)


@dataclass(frozen=True)
class NutritionProfile:
    display_name: str
    category: str
    default_gram: int
    calories_per_100g: float
    protein_per_100g: float
    fat_per_100g: float
    carbohydrate_per_100g: float
    fiber_per_100g: float

    def totals(self, gram: int | None = None) -> dict[str, float]:
        factor = (gram if gram is not None else self.default_gram) / 100
        return {
            "calories": round(self.calories_per_100g * factor, 2),
            "protein": round(self.protein_per_100g * factor, 2),
            "fat": round(self.fat_per_100g * factor, 2),
            "carbohydrate": round(self.carbohydrate_per_100g * factor, 2),
            "fiber": round(self.fiber_per_100g * factor, 2),
        }


def _display_name(value: str) -> str:
    return " ".join(
        part[:1].upper() + part[1:] for part in value.split("_") if part
    )


def _profile(
    key: str,
    category: str,
    gram: int,
    calories: float,
    protein: float,
    fat: float,
    carbohydrate: float,
    fiber: float,
) -> NutritionProfile:
    return NutritionProfile(
        display_name=_display_name(key),
        category=category,
        default_gram=gram,
        calories_per_100g=calories,
        protein_per_100g=protein,
        fat_per_100g=fat,
        carbohydrate_per_100g=carbohydrate,
        fiber_per_100g=fiber,
    )


def lookup(class_name: str) -> NutritionProfile | None:
    """Return a nutrition profile for a class name, or None for trays."""
    normalized = class_name.lower().strip().replace(" ", "_")
    if normalized in ("ompreng", "sekat_ompreng"):
        return None

    override = _OVERRIDES.get(normalized)
    if override is not None:
        category, gram, cal, protein, fat, carb, fiber = override
        return _profile(normalized, category, gram, cal, protein, fat, carb, fiber)

    if "telur" in normalized:
        return _profile(normalized, "Lauk", 60, 154, 12.4, 10.8, 0.7, 0)
    if "tempe" in normalized:
        return _profile(normalized, "Lauk", 80, 201, 19.9, 8.8, 13.5, 1.4)
    if "tahu" in normalized:
        return _profile(normalized, "Lauk", 80, 144, 10.9, 8.7, 2.8, 0.4)
    if "ayam" in normalized:
        return _profile(normalized, "Lauk", 80, 190, 27, 8.5, 2, 0)
    if "ikan" in normalized or normalized in ("lele_goreng", "nila_goreng"):
        return _profile(normalized, "Lauk", 75, 170, 23, 7.5, 1, 0)
    if "daging" in normalized or normalized in ("rendang", "empal"):
        return _profile(normalized, "Lauk", 75, 220, 25, 13, 2, 0)
    if "udang" in normalized or normalized in ("cumi", "teri"):
        return _profile(normalized, "Lauk", 75, 120, 21, 3, 1, 0)
    if normalized.startswith(_POKOK_PREFIXES):
        return _profile(normalized, "Pokok", 150, 170, 4, 2, 32, 2)
    if normalized.startswith(_SAYUR_PREFIXES):
        return _profile(normalized, "Sayur", 75, 35, 2, 0.4, 6, 2.5)
    if normalized.startswith(_BUAH_PREFIXES):
        return _profile(normalized, "Buah", 100, 60, 1, 0.3, 15, 2.5)
    if normalized.startswith(_SUSU_PREFIXES):
        return _profile(normalized, "Susu", 100, 100, 4, 4, 10, 0)
    if normalized.startswith(_NABATI_PREFIXES):
        return _profile(normalized, "Lauk Nabati", 80, 170, 10, 7, 12, 3)
    if normalized.startswith(_PELENGKAP_PREFIXES):
        return _profile(normalized, "Pelengkap", 20, 120, 2, 5, 16, 1)
    if normalized.startswith(_CAMILAN_PREFIXES):
        return _profile(normalized, "Camilan", 60, 250, 5, 12, 35, 2)
    return _profile(normalized, "Lainnya", 75, 100, 4, 3, 14, 2)
