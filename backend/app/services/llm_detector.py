"""Vision-LLM food detection (SumoPod / OpenAI-compatible chat completions)."""
from __future__ import annotations

import base64
import io
import json
import re

import httpx
from PIL import Image, ImageOps

from app.config import Settings
from app.schemas import BoundingBox, DetectionResponse, FoodItem, Nutrition


class LlmError(RuntimeError):
    pass


_SYSTEM_PROMPT = (
    "Kamu adalah ahli gizi dan vision AI profesional. Jawab murni HANYA dengan JSON valid "
    "tanpa markdown, tanpa penjelasan tambahan, tanpa prolog atau epilog. "
    "Nilai nutrisi adalah estimasi per porsi yang terlihat di gambar. "
    "Pastikan bounding box presisi mengelilingi porsi makanan secara individual, "
    "termasuk makanan atau minuman yang masih berada di dalam kemasan, botol, kaleng, "
    "sachet, atau bungkus."
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
1. Identifikasi setiap jenis makanan dan minuman yang terlihat, dipisah per jenis (misal: Nasi, Ayam Goreng, Sayur Kangkung).
2. Deteksi juga item yang masih terbungkus kemasan: susu kotak/karton, botol air atau minuman, kaleng, sachet, bungkus snack, cup, dus, dan makanan yang dilapisi plastik, kertas, atau daun. Kemasan bukan alasan untuk melewatkan item.
3. Untuk item berkemasan, sebutkan jenis kemasan dan isinya, serta merek dan ukuran bila terbaca di label (contoh: "Susu UHT Kotak Indomilk Kids 125 ml", "Air Mineral Botol 600 ml", "Snack Bungkus Keripik 40 g").
4. Jangan mengarang makanan yang tidak terlihat. Jika isi kemasan tidak terbaca, tetap catat itemnya dengan perkiraan wajar dan turunkan nilai confidence.
5. Estimasi berat (gram) dan nutrisi untuk ukuran porsi yang terlihat di foto. Untuk minuman, gunakan volume dalam mililiter sebagai perkiraan gram.
6. Buat bounding box untuk setiap item, mengelilingi kemasannya bila item berkemasan. Format bbox: [x1, y1, x2, y2] — (x1, y1) adalah pojok KIRI-ATAS kotak dan (x2, y2) adalah pojok KANAN-BAWAH kotak. Semua nilai float 0.0 sampai 1.0 hasil normalisasi terhadap lebar dan tinggi gambar. Wajib x2 > x1 dan y2 > y1. JANGAN mengirim lebar atau tinggi kotak.
7. Daftarkan SEMUA item yang terlihat tanpa membatasi jumlahnya, berapa pun banyaknya di dalam ompreng.
8. Jika foto bukan makanan, kembalikan array "items" kosong dan isi alasannya di "summary".

FORMAT OUTPUT:
Kembalikan HANYA JSON berformat persis seperti ini:
{{
  "items": [
    {{
      "name": "Nama Makanan atau Minuman",
      "category": "Pokok|Lauk|Sayur|Buah|Minuman|Lainnya",
      "estimatedGram": 150,
      "confidence": 0.95,
      "bbox": [0.1, 0.2, 0.4, 0.5],
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


def _extract_json_object(text: str) -> dict | None:
    """Return the first balanced ``{...}`` block found in ``text``.

    Vision models occasionally wrap the payload in prose or markdown, or leave
    trailing text after the closing brace. Scanning for the matching brace is
    more forgiving than ``json.loads`` on the whole string.
    """
    start = text.find("{")
    if start == -1:
        return None

    depth = 0
    in_string = False
    escaped = False
    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                try:
                    value = json.loads(text[start : index + 1])
                except json.JSONDecodeError:
                    return None
                return value if isinstance(value, dict) else None
    return None


def _parse_json_payload(text: str, required_key: str = "items") -> dict | None:
    """Best-effort parse of a model reply into an object holding ``required_key``."""
    if not text or not text.strip():
        return None

    def usable(value: object) -> dict | None:
        if isinstance(value, dict) and required_key in value:
            return value
        return None

    for candidate in (text, _strip_markdown_fence(text)):
        try:
            value = json.loads(candidate)
        except json.JSONDecodeError:
            continue
        parsed = usable(value)
        if parsed is not None:
            return parsed

    return usable(_extract_json_object(text))


async def _repair_json(
    settings: Settings,
    base_url: str,
    raw_text: str,
    shape_instruction: str,
    required_key: str = "items",
) -> dict | None:
    """Ask the model to turn an unparsable reply into strict JSON.

    The second pass is text-only (no image), so it is cheap and fast, and it
    keeps the user from seeing a hard error just because the first reply was
    wrapped in prose or had a trailing comma.
    """
    snippet = (raw_text or "").strip()
    if not snippet:
        return None
    if len(snippet) > 12000:
        snippet = snippet[:12000]

    payload = {
        "model": settings.llm_model,
        "stream": False,
        "temperature": 0,
        "max_tokens": 8192,
        "messages": [
            {
                "role": "system",
                "content": (
                    "Kamu adalah pengubah teks menjadi JSON. Balas HANYA dengan satu objek "
                    "JSON valid. Tanpa markdown, tanpa penjelasan, tanpa teks lain."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"{shape_instruction} "
                    "Pertahankan semua data yang ada di teks, jangan menambah atau "
                    "mengurangi, dan jangan mengarang nilai baru.\n\n"
                    f"TEKS:\n{snippet}"
                ),
            },
        ],
    }

    try:
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
            return None
        body = response.json()
        choices = body.get("choices") if isinstance(body, dict) else None
        if not isinstance(choices, list) or not choices:
            return None
        message = choices[0].get("message") if isinstance(choices[0], dict) else None
        if not isinstance(message, dict):
            return None
        return _parse_json_payload(
            _content_to_json_text(message.get("content")), required_key
        )
    except (httpx.HTTPError, ValueError, LlmError, KeyError, TypeError):
        return None


_DETECTION_SHAPE = (
    "Ubah teks berikut menjadi satu objek JSON valid dengan bentuk "
    '{"items": [...], "summary": "...", "akgAssessment": "..."}. '
    "Setiap item memakai kunci: name, category, estimatedGram, "
    "confidence, bbox ([x1, y1, x2, y2] ternormalisasi 0-1: pojok kiri-atas "
    "lalu pojok kanan-bawah), dan "
    "nutrition {calories, protein, fat, carbohydrate, fiber}."
)


async def _repair_payload(
    settings: Settings,
    base_url: str,
    raw_text: str,
) -> dict | None:
    return await _repair_json(
        settings, base_url, raw_text, _DETECTION_SHAPE, required_key="items"
    )


async def complete_json(
    settings: Settings,
    system_prompt: str,
    user_prompt: str,
    required_key: str,
    shape_instruction: str,
    *,
    temperature: float = 0.2,
    max_tokens: int = 4096,
) -> dict:
    """Run a text-only completion and return it as a JSON object.

    Shares the same JSON recovery as detection: strict parse first, then a
    text-only repair pass when the model wraps its answer in prose.
    """
    if not settings.sumopod_api_key:
        raise LlmError("SUMOPOD_API_KEY belum diatur pada backend.")

    base_url = settings.sumopod_api_base_url.rstrip("/")
    payload = {
        "model": settings.llm_model,
        "stream": False,
        "temperature": temperature,
        "max_tokens": max_tokens,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
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
        raise LlmError("AI Gateway mengembalikan respons JSON yang tidak valid.") from exc

    choices = body.get("choices") if isinstance(body, dict) else None
    if not isinstance(choices, list) or not choices or not isinstance(choices[0], dict):
        raise LlmError("Respons router AI tidak memuat hasil model.")
    message = choices[0].get("message")
    if not isinstance(message, dict):
        raise LlmError("Respons router AI tidak memuat pesan model.")

    json_text = _content_to_json_text(message.get("content"))
    if not json_text:
        raise LlmError(
            "AI tidak mengembalikan hasil "
            f"(finish_reason: {choices[0].get('finish_reason')}). Coba lagi."
        )

    parsed = _parse_json_payload(json_text, required_key)
    if parsed is None:
        parsed = await _repair_json(
            settings, base_url, json_text, shape_instruction, required_key
        )
    if parsed is None:
        raise LlmError("AI mengembalikan format yang tidak bisa dibaca. Coba lagi.")
    return parsed


def _number(value: object) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).strip()
    try:
        return float(text)
    except (TypeError, ValueError):
        pass
    # Models sometimes answer "150 gram" or "0,9" instead of a bare number.
    match = re.search(r"-?\d+(?:[.,]\d+)?", text)
    if match:
        try:
            return float(match.group(0).replace(",", "."))
        except ValueError:
            return 0.0
    return 0.0


def _bbox(value: object) -> BoundingBox | None:
    """Normalise a model bounding box into x/y/width/height in 0..1 space.

    The prompt asks for corner coordinates (``[x1, y1, x2, y2]``), which is what
    vision models produce naturally; asking for width/height made them answer
    with the bottom-right corner instead, which rendered as tall vertical strips.
    Payloads that already carry x/y/width/height are still accepted.
    """
    if isinstance(value, dict):
        if any(key in value for key in ("x1", "y1", "x2", "y2")):
            left = _number(value.get("x1"))
            top = _number(value.get("y1"))
            right = _number(value.get("x2"))
            bottom = _number(value.get("y2"))
        else:
            left = _number(value.get("x"))
            top = _number(value.get("y"))
            right = left + _number(value.get("width", value.get("w")))
            bottom = top + _number(value.get("height", value.get("h")))
    elif isinstance(value, list) and len(value) == 4:
        left, top, right, bottom = (_number(part) for part in value)
    else:
        return None

    x = min(max(min(left, right), 0.0), 1.0)
    y = min(max(min(top, bottom), 0.0), 1.0)
    width = min(max(abs(right - left), 0.0), 1.0 - x)
    height = min(max(abs(bottom - top), 0.0), 1.0 - y)
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


def _upright(image_bytes: bytes, mime_type: str) -> tuple[bytes, str]:
    """Bake EXIF rotation into the pixels before uploading to the model.

    Phone photos often store a landscape frame plus an EXIF rotation tag. When
    the model ignores that tag it answers in the unrotated frame, so the boxes
    end up rotated off the food. Rotating the pixels first keeps both sides in
    the same coordinate space.
    """
    try:
        with Image.open(io.BytesIO(image_bytes)) as image:
            if image.getexif().get(274, 1) in (None, 1):
                return image_bytes, mime_type
            oriented = ImageOps.exif_transpose(image) or image
            buffer = io.BytesIO()
            oriented.convert("RGB").save(buffer, format="JPEG", quality=92)
            return buffer.getvalue(), "image/jpeg"
    except (OSError, ValueError):
        return image_bytes, mime_type


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

    image_bytes, mime_type = _upright(image_bytes, mime_type)

    base_url = settings.sumopod_api_base_url.rstrip("/")
    payload = {
        "model": settings.llm_model,
        "stream": False,
        "temperature": 0.1,
        "max_tokens": 8192,
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
    finish_reason = choice.get("finish_reason")
    if not json_text:
        raise LlmError(
            "AI tidak mengembalikan hasil "
            f"(finish_reason: {finish_reason}). Coba analisis ulang."
        )

    parsed = _parse_json_payload(json_text)
    if parsed is None:
        # The model replied with something that is not strict JSON (prose
        # wrapper, trailing comma, truncated output). Ask it to convert the
        # reply instead of failing the whole scan.
        parsed = await _repair_payload(settings, base_url, json_text)
    if parsed is None:
        raise LlmError(
            "AI mengembalikan format yang tidak bisa dibaca "
            f"(finish_reason: {finish_reason}). Coba analisis ulang."
        )

    raw_items = parsed["items"]
    items = [
        _parse_item(item)
        for item in raw_items
        if isinstance(item, dict) and str(item.get("name") or "").strip()
    ]

    return DetectionResponse(
        engine="llm",
        model=settings.llm_model,
        items=items,
        summary=str(parsed.get("summary") or ""),
        akg_assessment=str(parsed.get("akgAssessment") or ""),
    )
