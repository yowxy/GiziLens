"""Vision-LLM food detection (SumoPod / OpenAI-compatible chat completions)."""
from __future__ import annotations

import base64
import json
import re

import httpx

from app.config import Settings
from app.schemas import BoundingBox, DetectionResponse, FoodItem, Nutrition


class LlmError(RuntimeError):
    pass


_SYSTEM_PROMPT = (
    "Kamu adalah ahli gizi dan vision AI profesional. Jawab murni HANYA dengan JSON valid "
    "tanpa markdown, tanpa penjelasan tambahan, tanpa prolog atau epilog. "
    "Nilai nutrisi adalah estimasi per porsi yang terlihat di gambar. "
    "Pastikan bounding box presisi mengelilingi porsi makanan secara individual."
)


def _user_prompt(
    target_group: str,
    calories: float,
    protein: float,
    fat: float,
    carbohydrate: float,
    fiber: float,
) -> str:
    return f"""Analisis gambar ompreng/baki makanan ini secara detail.

KONTEKS TARGET GIZI (AKG 2019):
- Kelompok: {target_group}
- Standar Makan Siang: Energi {calories:.0f} kkal | Protein {protein:.1f} g | Lemak {fat:.1f} g | Karbohidrat {carbohydrate:.1f} g | Serat {fiber:.1f} g.

INSTRUKSI WAJIB:
1. Identifikasi setiap jenis makanan/minuman yang terlihat jelas secara terpisah (misal: Nasi, Ayam Goreng, Sayur Kangkung).
2. Jangan mengarang makanan yang tidak terlihat.
3. Estimasi berat (gram) dan nutrisi untuk ukuran porsi yang terlihat di foto.
4. Buat bounding box untuk setiap item. Format bbox: [x_min, y_min, lebar, tinggi]. Nilai berupa float 0.0 hingga 1.0 yang dinormalisasi (relatif terhadap dimensi gambar). Titik (0,0) adalah pojok kiri atas.
5. Jika foto bukan makanan, kembalikan array "items" kosong dan isi alasannya di "summary".

FORMAT OUTPUT:
Kembalikan HANYA JSON berformat persis seperti ini:
{{
  "items": [
    {{
      "name": "Nama Makanan",
      "category": "Pokok|Lauk|Sayur|Buah|Minuman|Lainnya",
      "estimatedGram": 150,
      "confidence": 0.95,
      "bbox": [0.1, 0.2, 0.4, 0.3],
      "nutrition": {{
        "calories": 200,
        "protein": 5.5,
        "fat": 1.2,
        "carbohydrate": 40.0,
        "fiber": 1.0
      }}
    }}
  ],
  "summary": "Penjelasan singkat mengenai isi piring.",
  "akgAssessment": "Analisis singkat apakah total nutrisi di gambar ini sudah memenuhi atau melebihi target AKG di atas."
}}"""


def _strip_markdown_fence(value: str) -> str:
    trimmed = value.strip()
    if trimmed.startswith("```"):
        trimmed = re.sub(r"^```(?:json)?\s*", "", trimmed)
        trimmed = re.sub(r"\s*```$", "", trimmed)
    return trimmed.strip()


def _content_to_json_text(content: object) -> str:
    if isinstance(content, str):
        return _strip_markdown_fence(content)
    if isinstance(content, list):
        text = "".join(
            part["text"]
            for part in content
            if isinstance(part, dict) and isinstance(part.get("text"), str)
        )
        return _strip_markdown_fence(text)
    raise LlmError("Respons API AI tidak berisi JSON.")


def _number(value: object) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    try:
        return float(str(value))
    except (TypeError, ValueError):
        return 0.0


def _bbox(value: object) -> BoundingBox | None:
    if not isinstance(value, list) or len(value) != 4:
        return None
    x = min(max(_number(value[0]), 0.0), 1.0)
    y = min(max(_number(value[1]), 0.0), 1.0)
    width = min(max(_number(value[2]), 0.0), 1.0 - x)
    height = min(max(_number(value[3]), 0.0), 1.0 - y)
    if width <= 0 or height <= 0:
        return None
    return BoundingBox(x=x, y=y, width=width, height=height)


def _parse_item(raw: dict) -> FoodItem:
    nutrition = raw.get("nutrition") or {}
    if not isinstance(nutrition, dict):
        nutrition = {}
    return FoodItem(
        name=str(raw.get("name") or "").strip(),
        category=str(raw.get("category") or "Lainnya").strip() or "Lainnya",
        estimated_gram=int(min(max(round(_number(raw.get("estimatedGram"))), 1), 2000)),
        confidence=min(max(_number(raw.get("confidence")), 0.0), 1.0),
        bbox=_bbox(raw.get("bbox")),
        nutrition=Nutrition(
            calories=_number(nutrition.get("calories")),
            protein=_number(nutrition.get("protein")),
            fat=_number(nutrition.get("fat")),
            carbohydrate=_number(nutrition.get("carbohydrate")),
            fiber=_number(nutrition.get("fiber")),
        ),
    )


async def detect(
    settings: Settings,
    image_bytes: bytes,
    mime_type: str,
    target_group: str,
    calories: float,
    protein: float,
    fat: float,
    carbohydrate: float,
    fiber: float,
) -> DetectionResponse:
    if not settings.sumopod_api_key:
        raise LlmError("SUMOPOD_API_KEY belum diatur pada backend.")

    base_url = settings.sumopod_api_base_url.rstrip("/")
    payload = {
        "model": settings.llm_model,
        "stream": False,
        "temperature": 0.1,
        "max_tokens": 4096,
        "messages": [
            {"role": "system", "content": _SYSTEM_PROMPT},
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": _user_prompt(
                            target_group, calories, protein, fat, carbohydrate, fiber
                        ),
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{mime_type};base64,"
                            f"{base64.b64encode(image_bytes).decode('ascii')}"
                        },
                    },
                ],
            },
        ],
    }

    async with httpx.AsyncClient(timeout=settings.llm_timeout_seconds) as client:
        response = await client.post(
            f"{base_url}/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.sumopod_api_key}",
                "Accept": "application/json",
                "Content-Type": "application/json",
            },
            json=payload,
        )

    if response.status_code < 200 or response.status_code >= 300:
        raise LlmError(f"API AI gagal ({response.status_code}): {response.text}")

    try:
        body = response.json()

    except ValueError as exc:
        print(
            "[AI DEBUG]",
            "Status:", response.status_code,
            "Content-Type:", response.headers.get("content-type"),
            "Response length:", len(response.content),
            "Starts with SSE:", response.text.lstrip().startswith("data:"),
            flush=True,
        )

        raise LlmError(
            "AI Gateway mengembalikan respons JSON yang tidak valid."
        ) from exc

    if not isinstance(body, dict):
        raise LlmError("Format respons AI Gateway tidak sesuai.")

    choices = body.get("choices") if isinstance(body, dict) else None
    if not isinstance(choices, list) or not choices or not isinstance(choices[0], dict):
        raise LlmError("Respons router AI tidak memuat hasil model.")
    choice = choices[0]
    message = choice.get("message")
    if not isinstance(message, dict):
        raise LlmError("Respons router AI tidak memuat pesan model.")
    json_text = _content_to_json_text(message.get("content"))
    if not json_text:
        raise LlmError(
            "AI tidak mengembalikan hasil "
            f"(finish_reason: {choice.get('finish_reason')}). Coba analisis ulang."
        )

    try:
        parsed = json.loads(json_text)
    except json.JSONDecodeError as exc:
        raise LlmError(f"JSON dari AI tidak valid: {exc}") from exc

    if not isinstance(parsed, dict) or not isinstance(parsed.get("items"), list):
        raise LlmError("Hasil model tidak memuat daftar makanan.")
    raw_items = parsed["items"]
    items = [
        _parse_item(item)
        for item in raw_items
        if isinstance(item, dict) and str(item.get("name") or "").strip()
    ][:5]

    return DetectionResponse(
        engine="llm",
        model=settings.llm_model,
        items=items,
        summary=str(parsed.get("summary") or ""),
        akg_assessment=str(parsed.get("akgAssessment") or ""),
    )
