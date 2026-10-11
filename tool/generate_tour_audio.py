"""Pre-records the Marathi and Hindi guided-tour narration as bundled MP3s.

Why: on-device TTS often has no Marathi/Hindi voice data installed (it reports
the language as available, then speaks nothing), and the streaming fallback
needs a network the target users often do not have. Bundled clips play offline
on every phone.

Each clip is named `{lang}_{fnv1a32(text)}.mp3`; `TtsService` computes the same
hash at runtime, so any narration string that has a clip plays it and anything
else falls back to device TTS. Re-run after editing tour text:

    python -m pip install edge-tts
    python tool/generate_tour_audio.py
"""
import asyncio
import os
import re

import edge_tts

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio", "tour")
SOURCES = [
    "lib/features/patient/patient_dashboard_screen.dart",
    "lib/features/doctor/doctor_dashboard_screen.dart",
    "lib/features/operator/operator_dashboard_screen.dart",
    "lib/features/admin/admin_dashboard_screen.dart",
    "lib/shared/widgets/guided_tour_dialog.dart",
]
VOICES = {"mr": "mr-IN-AarohiNeural", "hi": "hi-IN-SwaraNeural"}
STR = r"'((?:[^'\\]|\\.)*)'"
PATTERNS = {
    "mr": [r"audioMr:\s*" + STR, r"marathiAudio\s*=\s*" + STR],
    "hi": [r"audioHi:\s*" + STR, r"hindiAudio\s*=\s*" + STR],
}


def fnv1a32(text: str) -> str:
    h = 0x811C9DC5
    for b in text.encode("utf-8"):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return f"{h:08x}"


def collect():
    items = set()
    for rel in SOURCES:
        src = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        for lang, pats in PATTERNS.items():
            for pat in pats:
                for m in re.finditer(pat, src):
                    text = m.group(1).replace("\\'", "'").strip()
                    if text:
                        items.add((lang, text))
    return sorted(items)


async def main():
    os.makedirs(OUT, exist_ok=True)
    items = collect()
    wanted = set()
    for lang, text in items:
        name = f"{lang}_{fnv1a32(text)}.mp3"
        wanted.add(name)
        path = os.path.join(OUT, name)
        if os.path.exists(path):
            continue
        await edge_tts.Communicate(text, VOICES[lang], rate="-8%").save(path)
        print("recorded", name)
    for f in os.listdir(OUT):
        if f.endswith(".mp3") and f not in wanted:
            os.remove(os.path.join(OUT, f))
            print("removed stale", f)
    print(f"{len(items)} clips")


asyncio.run(main())
