"""Unit tests for the read-only V3 candidate scanner."""
import json
import unittest
from scripts.v3_quality_check import inspect, scan, translation_buildable, scoring_sequence_matches

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

    def test_punctuation_differences_are_not_false_flags(self):
        self.assertTrue(translation_buildable("Cơm, nước", ["Cơm", "nước"]))
        self.assertTrue(translation_buildable("茶、咖啡", ["茶", "咖啡"]))
        self.assertTrue(translation_buildable("Đây là cháo.", ["Đây", "là", "cháo"]))

    def test_unbuildable_translation_flag_needs_review(self):
        issues = inspect({"source_table": "duo_challenges", "id": "broken",
            "type": "translate", "prompt": "你好",
            "solutions": ["xin chào"], "choices_text": ["tạm", "biệt"]})
        self.assertIn("translation_token_bank_not_buildable_candidate",
                      [row["issue_code"] for row in issues])

    def test_reuse_of_tile_is_not_silently_allowed(self):
        self.assertFalse(translation_buildable("trà trà", ["trà"]))
        self.assertTrue(translation_buildable("trà trà", ["trà", "trà"]))

    def test_actual_flutter_ranked_scoring_matches_translation(self):
        row = {"source_table": "duo_challenges", "id": "from-unit-1",
               "type": "translate", "prompt": "米饭和豆腐",
               "choices_text": ["và", "đậu", "cháo", "phụ", "cơm", "nóng"],
               "choices_correct": [2, 3, 0, 4, 1, 0],
               "solutions": ["cơm và đậu phụ"]}
        self.assertTrue(scoring_sequence_matches(row))
        self.assertEqual(inspect(row), [])

    def test_scoring_mismatch_catches_incorrect_key(self):
        row = {"source_table": "duo_challenges", "id": "bad-order",
               "type": "translate", "prompt": "米饭和豆腐",
               "choices_text": ["và", "đậu", "cháo", "phụ", "cơm", "nóng"],
               "choices_correct": [1, 3, 0, 4, 2, 0],
               "solutions": ["cơm và đậu phụ"]}
        self.assertFalse(scoring_sequence_matches(row))
        self.assertIn("translation_scorer_solution_mismatch_candidate",
                      [x["issue_code"] for x in inspect(row)])

    def test_scoring_sequence_must_be_contiguous(self):
        row = {"type": "translate", "choices_text": ["我", "你"],
               "choices_correct": [1, 3], "solutions": ["我你"]}
        self.assertFalse(scoring_sequence_matches(row))

    def test_hanzi_stroke_count_matches_path_segments(self):
        issues = inspect({"source_table": "lexicon_characters", "id": 1,
                          "character": "水", "stroke_count": 4,
                          "stroke_paths": "M0 0|M1 1|M2 2|M3 3"})
        self.assertEqual(issues, [])

    def test_hanzi_stroke_mismatch_is_flagged(self):
        issues = inspect({"source_table": "lexicon_characters", "id": 2,
                          "character": "你", "stroke_count": 3,
                          "stroke_paths": "M0 0|M1 1"})
        self.assertIn("stroke_count_path_mismatch",
                      [x["issue_code"] for x in issues])

    def test_hanzi_missing_strokes_blocks_content(self):
        issues = inspect({"source_table": "lexicon_characters", "id": 3,
                          "character": "好", "stroke_count": 0,
                          "stroke_paths": ""})
        codes = {x["issue_code"] for x in issues}
        self.assertEqual(codes, {"invalid_stroke_count", "missing_stroke_paths"})

    def test_stream_counts_multiple_sources(self):
        report = scan([json.dumps({"source_table":"lexicon_words","id":1,
            "word":"你好","pinyin":"nǐ hǎo","meaning_vi":"xin chào"})+"\n",
            json.dumps({"source_table":"lexicon_words","id":2,
            "word":"谢谢","pinyin":None,"meaning_vi":"cảm ơn"})+"\n"])
        self.assertEqual(report["rows_by_source"]["lexicon_words"], 2)
        self.assertEqual(report["total_candidates"], 1)

if __name__ == "__main__":
    unittest.main()
