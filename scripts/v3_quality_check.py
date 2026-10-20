#!/usr/bin/env python3
"""Offline, read-only V3 editorial candidate scanner.

Input: JSON Lines with `source_table` + original row columns, as exported
from Supabase in bounded pages. No API keys, no writes, no auto-translations.
Output: JSON issue candidates; human approval required.
"""
import argparse
import json
import pathlib
import unicodedata
from collections import Counter

TABLES = {"lexicon_words", "lexicon_examples", "lexicon_characters", "duo_challenges"}
ARRAY_FIELDS = ("choices_text", "choices_correct", "tokens_text", "solutions")

def is_blank(x):
    return x is None or isinstance(x, str) and not x.strip()

def translation_buildable(solution, choices):
    """Can target be assembled from each available answer-bank tile at most once?

    Conservative review heuristic only: answer scoring may allow other
    representations or punctuation. Skip long banks to avoid exponential work.
    """
    if not isinstance(solution, str) or not isinstance(choices, list):
        return None
    if len(choices) > 16 or any(not isinstance(c, str) for c in choices):
        return None
    def normal(text):
        return "".join(ch for ch in text.casefold()
                       if not ch.isspace()
                       and not unicodedata.category(ch).startswith("P"))
    target = normal(solution)
    options = [normal(choice) for choice in choices]
    if not target or not options or any(not x for x in options):
        return None
    states = {(0, 0)}
    while states:
        next_states = set()
        for offset, used in states:
            if offset == len(target):
                return True
            for i, token in enumerate(options):
                if not used & (1 << i) and target.startswith(token, offset):
                    next_states.add((offset + len(token), used | (1 << i)))
        states = next_states
    return False


def scoring_sequence_matches(row):
    """Check actual DuoSentenceBuilder 1..N choice ranking against solutions.

    The production widget grades choices_correct positions in order, rather
    than comparing assembled answer with solutions directly.
    Return None if source shape is not suitable for this comparison.
    """
    choices = row.get("choices_text")
    ranking = row.get("choices_correct")
    solutions = row.get("solutions")
    if not isinstance(choices, list) or not isinstance(ranking, list) or not isinstance(solutions, list):
        return None
    if len(choices) != len(ranking) or not choices or not solutions:
        return False
    if not all(isinstance(v, (bool, int)) for v in ranking):
        return False
    numbers = [int(v) for v in ranking if int(v) > 0]
    if sorted(numbers) != list(range(1, len(numbers) + 1)):
        return False
    ordered = sorted(((int(rank), choice) for rank, choice in zip(ranking, choices)
                      if int(rank) > 0), key=lambda pair: pair[0])
    if not all(isinstance(text, str) for _, text in ordered):
        return None
    def normalize(value):
        if not isinstance(value, str):
            return None
        return "".join(ch for ch in value.casefold()
                       if not ch.isspace() and not unicodedata.category(ch).startswith("P"))
    result = normalize("".join(text for _, text in ordered))
    expected = [normalize(text) for text in solutions]
    if result is None or not result or any(v is None for v in expected):
        return None
    return result in expected


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
    elif source == "lexicon_characters":
        if is_blank(row.get("character")):
            flag("missing_character", "critical", {})
        stroke_count = row.get("stroke_count")
        stroke_paths = row.get("stroke_paths")
        if not isinstance(stroke_count, int) or isinstance(stroke_count, bool) or stroke_count <= 0:
            flag("invalid_stroke_count", "critical", {"stroke_count": stroke_count})
        if is_blank(stroke_paths):
            flag("missing_stroke_paths", "critical", {})
        elif isinstance(stroke_paths, str) and isinstance(stroke_count, int) and not isinstance(stroke_count, bool):
            parsed_count = len([p for p in stroke_paths.split("|") if p.strip()])
            if parsed_count != stroke_count:
                flag("stroke_count_path_mismatch", "high",
                     {"stroke_count": stroke_count, "path_count": parsed_count})
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
            if isinstance(row.get("solutions"), list) and isinstance(row.get("choices_text"), list):
                checked = [
                    translation_buildable(sol, row["choices_text"])
                    for sol in row["solutions"]
                ]
                if checked and all(value is False for value in checked):
                    flag("translation_token_bank_not_buildable_candidate", "high",
                         {"type": typ, "hint": "Review tile split, punctuation and alternate scoring"})
            scoring = scoring_sequence_matches(row)
            if scoring is False:
                flag("translation_scorer_solution_mismatch_candidate", "high",
                     {"type": typ, "hint": "Flutter grades choices_correct 1..N, compare with valid solutions"})
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
