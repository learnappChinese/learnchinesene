"""Learner-centric Unit acceptance audit, read-only, with explainable issues.

Input JSON: {"unit_id": "...", "objective": "...", "challenges": [{...}],
"words": [{...}], "examples":[{...}], "path_rows":[{...}], "boss_stage": {...}}.
Reports structural evidence and review prompts, NOT correctness of translations.
"""
import json
import pathlib
import argparse
from collections import Counter, defaultdict

RECOGNITION = {"select","assist","match"}
LISTENING = {"listenTap"}
PRODUCTION = {"translate","gapFill","tapComplete","orderTapComplete","patternTapComplete","dialogue"}

def check_unit(unit):
    uid = str(unit.get("unit_id",""))
    issues = []
    def flag(code, severity, evidence, subject=None):
        issues.append({"code":code,"severity":severity,"unit_id":uid,
                       "subject":subject,"evidence":evidence,
                       "status":"needs_review"})
    challenges = unit.get("challenges",[])
    words = unit.get("words",[])
    examples = unit.get("examples",[])
    path = unit.get("path_rows",[])
    if not isinstance(challenges,list) or not isinstance(words,list) or not isinstance(examples,list):
        return {"unit_id":uid,"status":"blocked","issues":[{"code":"invalid_export_shape"}]}
    if not str(unit.get("objective") or "").strip():
        flag("teaching_objective_missing","high",{"field":"objective"})
    if not challenges:
        flag("no_challenges","critical",{})
    if not words:
        flag("no_unit_words","medium",{"hint":"verify Unit-to-lexicon mapping, not necessarily absent content"})
    counts = Counter(str(x.get("type","")) for x in challenges)
    if not (set(counts)&RECOGNITION):
        flag("recognition_phase_missing","medium",dict(counts))
    if not (set(counts)&LISTENING):
        flag("listening_phase_missing","medium",dict(counts))
    if not (set(counts)&PRODUCTION):
        flag("production_phase_missing","medium",dict(counts))
    seen_ids = set()
    signatures = defaultdict(list)
    for c in challenges:
        cid = str(c.get("id",""))
        if not cid or cid in seen_ids:
            flag("duplicate_or_missing_challenge_id","critical",{"id":cid},cid)
        seen_ids.add(cid)
        kind = c.get("type")
        if kind == "translate":
            if not c.get("solutions") or not c.get("choices_text"):
                flag("unanswerable_translate","critical",{"id":cid},cid)
        if kind in {"select","assist","listenTap"} and not c.get("choices_correct"):
            flag("unanswerable_choice","critical",{"id":cid},cid)
        signature = (kind,str(c.get("session_id","")),str(c.get("prompt","")),
                     json.dumps(c.get("choices_text"),ensure_ascii=False,sort_keys=True))
        signatures[signature].append(cid)
    for group in signatures.values():
        if len(group)>1:
            flag("repeated_question_candidate","medium",{"ids":group[:10],"count":len(group)})
    for w in words:
        if not str(w.get("pinyin") or "").strip():
            flag("word_missing_pinyin","high",{"word":w.get("word")},str(w.get("id")))
        if not str(w.get("meaning_vi") or "").strip():
            flag("word_missing_vietnamese","high",{"word":w.get("word")},str(w.get("id")))
    for ex in examples:
        if not all(str(ex.get(k) or "").strip() for k in ("sentence_cn","sentence_vi","sentence_pinyin")):
            flag("example_incomplete","high",{"example_id":ex.get("id")},str(ex.get("id")))
    boss = unit.get("boss_stage")
    if not boss:
        flag("boss_metadata_missing","high",{})
    if path and not any(x.get("node_type")=="learning" for x in path):
        flag("learning_path_missing","critical",{})
    if path and not any(x.get("node_type")=="boss" for x in path):
        flag("boss_node_missing","high",{})
    critical = any(i.get("severity")=="critical" for i in issues)
    return {"unit_id":uid,"status":"blocked" if critical else "requires_human_review",
            "question_count":len(challenges),"words_count":len(words),
            "examples_count":len(examples),"question_types":dict(counts),
            "issues":issues,
            "human_review_required":["Mandarin/Vietnamese translation equivalence",
              "HSK difficulty and pedagogical sequence","audio quality and tone",
              "correct-answer alternatives and token-bank solvability",
              "mission completion, Guest progression, Boss and next Unit on device"]}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--input",required=True,type=pathlib.Path)
    p.add_argument("--output",required=True,type=pathlib.Path)
    args=p.parse_args()
    unit=json.loads(args.input.read_text(encoding="utf-8"))
    report=check_unit(unit)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    print(f"{report['unit_id']}: {report['status']}, {len(report['issues'])} review findings")
if __name__=="__main__":
    main()
