import unittest
from scripts.v3_feedback_triage import triage

class V3FeedbackTriageTests(unittest.TestCase):
    def test_positive_reviews_do_not_open_error_tickets(self):
        report = triage([
            {"unit_id": "sec_1_unit_1", "category": "lesson_ok", "lesson_rating": 4},
            {"unit_id": "sec_1_unit_1", "category": "lesson_ok", "lesson_rating": 5},
        ])
        self.assertEqual(report["issue_count"], 0)
        self.assertEqual(report["positive_unit_reviews"]["sec_1_unit_1"]["average_rating"], 4.5)

    def test_reports_are_grouped_by_precise_challenge_identity(self):
        report = triage([
            {"unit_id": "sec_1_unit_1", "level_id": "level1",
             "challenge_id": "q123", "category": "wrong_translation",
             "notes": "Nghĩa sai ngữ cảnh"},
            {"unit_id": "sec_1_unit_1", "level_id": "level1",
             "challenge_id": "q123", "category": "wrong_translation",
             "notes": "Thiếu nghĩa thứ hai"},
        ])
        self.assertEqual(report["issue_count"], 1)
        self.assertEqual(report["issues"][0]["report_count"], 2)
        self.assertFalse(report["issues"][0]["auto_corrected"])

    def test_critical_unlock_or_answer_wins_priority(self):
        report = triage([
            {"unit_id": "sec_1_unit_1", "category": "missing_explanation"},
            {"unit_id": "sec_1_unit_1", "category": "locked_progress"},
        ])
        self.assertEqual(report["issues"][0]["category"], "locked_progress")

    def test_bad_reports_are_rejected(self):
        report = triage([
            None,
            {"unit_id": "", "category": "lesson_ok", "lesson_rating": 4},
            {"unit_id": "sec_1_unit_1", "category": "unexpected"},
        ])
        self.assertEqual(report["invalid_reports"], 3)
        self.assertEqual(report["issue_count"], 0)

if __name__=="__main__":
    unittest.main()
