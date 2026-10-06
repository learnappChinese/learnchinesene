#!/usr/bin/env python3
"""Fail CI if Flutter TTS is instantiated/imported outside the shared service."""

from pathlib import Path

ROOT = Path("lib")
ALLOWED = Path("lib/core/services/tts_service.dart")
NEEDLES = (
    "FlutterTts(",
    "package:flutter_tts/flutter_tts.dart",
)

violations: list[tuple[Path, int, str]] = []

for path in ROOT.rglob("*.dart"):
    if path == ALLOWED:
        continue
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        continue
    for number, line in enumerate(lines, start=1):
        if any(needle in line for needle in NEEDLES):
            violations.append((path, number, line.strip()))

if violations:
    print("Direct Flutter TTS usage is forbidden outside TtsService:")
    for path, number, line in violations:
        print(f"  {path}:{number}: {line}")
    raise SystemExit(1)

print("TTS singleton guard passed.")
