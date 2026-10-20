"""Unit tests for the read-only V3 candidate scanner."""
import json
import unittest
from scripts.v3_quality_check import inspect, scan, translation_buildable

class ContentQualityScannerTests(unittest.TestCase):
    def test_missing_word_pinyin_is_flagged(self):
        issues = inspect({"source_table":"lexicon_words","id":1925,
                          "word":"t恤","pinyin":None,"meaning_vi":"áo thun"})
        self.assertIn("missing_pinyin", [x["issue_code"] for x in issues])

    def test_dialogue_missing_prompt_is_not_false_positive(self):
        issues = inspect({"source_table":"duo_challenges","id":"a","type":"dialogue",
                          "prompt":None,"solutions":None})
        self.assertEqual(issues, [])

    def test_translate_needs_answers(self):
        issues = inspect({"source_table":"duo_challenges","id":"a","type":"translate",
                          "prompt":"你好","solutions":[],"choices_text":[]})
        codes = {x["issue_code"] for x in issues}
        self.assertEqual(codes, {"translate_missing_solutions","translate_missing_choices"})

    def test_valid_translate_has_no_structural_findings(self):
        issues = inspect({"source_table":"duo_challenges","id":"a","type":"translate",
                          "prompt":"你好","solutions":["hello"],
                          "choices_text":["hello"],"choices_correct":[True],
                          "tokens_text":[]})
        self.assertEqual(issues, [])

    def test_translation_tiles_are_reconstructible(self):
        self.assertTrue(translation_buildable("cơm và đậu phụ",
                         ["và", "đậu", "cháo", "phụ", "cơm", "nóng"]))
        self.assertFalse(translation_buildable("cơm và nước",
                          ["và", "đậu", "cháo", "phụ", "cơm", "nóng"]))

    def test_unbuildable_translation_flag_needs_review(self):
        issues = inspect({"source_table": "duo_challenges", "id": "broken",
            "type": "translate", "prompt": "你好",
            "solutions": ["xin chào"], "choices_text": ["tạm", "biệt"]})
        self.assertIn("translation_token_bank_not_buildable_candidate",
                      [row["issue_code"] for row in issues])

    def test_reuse_of_tile_is_not_silently_allowed(self):
        self.assertFalse(translation_buildable("trà trà", ["trà"]))
        self.assertTrue(translation_buildable("trà trà", ["trà", "trà"]))

    def test_stream_counts_multiple_sources(self):
        report = scan([json.dumps({"source_table":"lexicon_words","id":1,
            "word":"你好","pinyin":"nǐ hǎo","meaning_vi":"xin chào"})+"\n",
            json.dumps({"source_table":"lexicon_words","id":2,
            "word":"谢谢","pinyin":None,"meaning_vi":"cảm ơn"})+"\n"])
        self.assertEqual(report["rows_by_source"]["lexicon_words"], 2)
        self.assertEqual(report["total_candidates"], 1)

if __name__ == "__main__":
    unittest.main()
