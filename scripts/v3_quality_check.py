#!/usr/bin/env python3
"""Offline, read-only V3 editorial candidate scanner.

Input: JSON Lines with `source_table` + original row columns, as exported
from Supabase in bounded pages. No API keys, no writes, no auto-translations.
Output: JSON issue candidates; human approval required.
"""
import argparse
import json
import pathlib
from collections import Counter

TABLES = {"lexicon_words", "lexicon_examples", "duo_challenges"}
ARRAY_FIELDS = ("choices_text", "choices_correct", "tokens_text", "solutions")

def is_blank(x):
    return x is None or isinstance(x, str) and not x.strip()

def inspect(row):
    source = row.get("source_table", "")
    item_id = str(row.get("id", ""))
    issues = []
    def flag(code, severity, detail):
        issues.append({"source_table": source, "source_id": item_id,
                       "issue_code": code, "severity": severity,
                       "evidence": detail})
    if source not in TABLES:
        flag("unsupported_source", "high", {"source": source})
        return issues
    if not item_id:
        flag("missing_id", "critical", {})
        return issues
    if source == "lexicon_words":
        if is_blank(row.get("word")):
            flag("missing_word", "critical", {})
        if is_blank(row.get("pinyin")):
            flag("missing_pinyin", "high", {"word": row.get("word")})
        if is_blank(row.get("meaning_vi")):
            flag("missing_meaning_vi", "high", {"word": row.get("word")})
    elif source == "lexicon_examples":
        for key in ("sentence_cn", "sentence_pinyin", "sentence_vi"):
            if is_blank(row.get(key)):
                flag("missing_" + key, "high", {})
    else:
        typ = row.get("type")
        if is_blank(typ):
            flag("missing_challenge_type", "critical", {})
        for key in ARRAY_FIELDS:
            value = row.get(key)
            if value is not None and not isinstance(value, list):
                flag("invalid_" + key + "_type", "high", {"type": typ})
        # Type-specific rules; blank prompt/solutions are valid for match,
        # dialogue and other challenge types. Never mark all of them broken.
        if typ == "translate":
            if is_blank(row.get("prompt")):
                flag("translate_missing_prompt", "high", {})
            if not isinstance(row.get("solutions"), list) or not row["solutions"]:
                flag("translate_missing_solutions", "critical", {})
            if not isinstance(row.get("choices_text"), list) or not row["choices_text"]:
                flag("translate_missing_choices", "critical", {})
        elif typ in ("assist", "select", "listenTap"):
            if not isinstance(row.get("choices_correct"), list) or not row["choices_correct"]:
                flag("choice_missing_correct", "critical", {"type": typ})
        # Do not infer translation correctness from JSON presence or direct TTS.
    return issues

def scan(lines):
    counts = Counter()
    issues = []
    for line_number, line in enumerate(lines, 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
            if not isinstance(row, dict):
                raise ValueError("JSON record must be an object")
            counts[row.get("source_table", "<missing>")] += 1
            issues.extend(inspect(row))
        except (ValueError, json.JSONDecodeError) as exc:
            issues.append({"source_table": "<parse>", "source_id": str(line_number),
                           "issue_code": "invalid_json_record", "severity": "high",
                           "evidence": {"line": line_number, "error": str(exc)}})
    return {"rows_by_source": dict(counts), "total_candidates": len(issues),
            "issue_counts": dict(Counter(x["issue_code"] for x in issues)),
            "candidate_issues": issues,
            "warning": "Candidate structural findings only. Semantic Chinese/Vietnamese review is required."}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    report = scan(args.input.open(encoding="utf-8"))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Scanned {sum(report['rows_by_source'].values())} rows; "
          f"{report['total_candidates']} structural review candidates.")
if __name__ == "__main__":
    main()
