#!/usr/bin/env python3
"""Review local learner feedback exports without mutating Supabase content.

Input is the JSON array explicitly copied from the debug QA sheet.
Output groups by exact lesson/question IDs so a bilingual reviewer can locate
the original record. Positive reviews are counted, not turned into issues.
"""
import argparse
import json
import pathlib
from collections import defaultdict, Counter

SEVERITY = {
    "wrong_answer": "critical",
    "locked_progress": "critical",
    "wrong_translation": "high",
    "missing_audio": "high",
    "missing_lesson_content": "high",
    "poor_sequence": "medium",
    "missing_explanation": "medium",
    "other": "medium",
}
RANK = {"critical": 0, "high": 1, "medium": 2, "low": 3}

def triage(entries):
    problems = defaultdict(list)
    positive = defaultdict(list)
    invalid = 0
    for item in entries:
        if not isinstance(item, dict):
            invalid += 1
            continue
        unit_id = str(item.get("unit_id") or "").strip()
        category = str(item.get("category") or "").strip()
        if not unit_id:
            invalid += 1
            continue
        if category == "lesson_ok":
            rating = item.get("lesson_rating")
            if isinstance(rating, int) and not isinstance(rating, bool) and 1 <= rating <= 5:
                positive[unit_id].append(rating)
            else:
                invalid += 1
            continue
        if category not in SEVERITY:
            invalid += 1
            continue
        question_id = str(item.get("challenge_id") or "").strip()
        level_id = str(item.get("level_id") or "").strip()
        key = (unit_id,level_id,question_id,category)
        problems[key].append(item)
    issues = []
    for (unit,level,challenge,category),items in problems.items():
        notes = []
        for item in items:
            note = str(item.get("notes") or "").strip()[:500]
            if note and note not in notes:
                notes.append(note)
            if len(notes) >= 3:
                break
        issues.append({
            "unit_id": unit,
            "level_id": level or None,
            "challenge_id": challenge or None,
            "category": category,
            "severity": SEVERITY[category],
            "report_count": len(items),
            "notes_for_reviewer": notes,
            "state": "needs_human_review",
            "auto_corrected": False,
        })
    issues.sort(key=lambda row: (
        RANK[row["severity"]], -row["report_count"],
        row["unit_id"], row["challenge_id"] or ""))
    return {
        "issue_count": len(issues),
        "invalid_reports": invalid,
        "positive_unit_reviews": {
            unit: {"count":len(scores),"average_rating":round(sum(scores)/len(scores),2)}
            for unit,scores in sorted(positive.items())
        },
        "severity_counts": dict(Counter(row["severity"] for row in issues)),
        "issues": issues,
        "warning": "Proposed reviewer queue only. No automatic data edits or Unit approvals.",
    }

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--input",required=True,type=pathlib.Path)
    parser.add_argument("--output",required=True,type=pathlib.Path)
    args=parser.parse_args()
    entries=json.loads(args.input.read_text(encoding="utf-8"))
    if not isinstance(entries,list):
        raise SystemExit("Input must be JSON array exported from V3 debug feedback.")
    report=triage(entries)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    print(f"{report['issue_count']} candidate issues; {report['invalid_reports']} rejected reports")
if __name__=="__main__":
    main()
