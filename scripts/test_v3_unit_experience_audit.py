import unittest
from scripts.v3_unit_experience_audit import check_unit

def good():
    return {
      "unit_id":"sec_1_unit_1","objective":"Tên thức ăn và đồ uống",
      "words":[{"id":1,"word":"茶","pinyin":"chá","meaning_vi":"trà"}],
      "examples":[{"id":1,"sentence_cn":"我喝茶。","sentence_pinyin":"Wǒ hē chá.","sentence_vi":"Tôi uống trà."}],
      "challenges":[
        {"id":"a","type":"select","session_id":1,"prompt":"茶","choices_correct":[True],"choices_text":["trà"]},
        {"id":"b","type":"listenTap","session_id":1,"prompt":"茶","choices_correct":[True],"choices_text":["trà"]},
        {"id":"c","type":"translate","session_id":1,"prompt":"我喝茶。","solutions":["Tôi uống trà."],"choices_text":["Tôi","uống","trà"]}
      ],
      "boss_stage":{"id":1},
      "path_rows":[{"node_type":"learning"},{"node_type":"boss"}]}

class UnitExperienceTests(unittest.TestCase):
    def test_sample_is_not_automatically_certified(self):
        report=check_unit(good())
        self.assertEqual(report["status"],"requires_human_review")
        self.assertEqual(report["issues"],[])
    def test_missing_listening_and_answers(self):
        unit=good()
        unit["challenges"]= [{"id":"bad","type":"translate","solutions":[],"choices_text":[]}]
        report=check_unit(unit)
        self.assertEqual(report["status"],"blocked")
        self.assertIn("unanswerable_translate",[x["code"] for x in report["issues"]])
        self.assertIn("listening_phase_missing",[x["code"] for x in report["issues"]])
    def test_duplicate_is_review_not_deletion(self):
        unit=good()
        unit["challenges"].append(dict(unit["challenges"][0],id="a2"))
        report=check_unit(unit)
        self.assertEqual(report["status"],"requires_human_review")
        self.assertIn("repeated_question_candidate",[x["code"] for x in report["issues"]])
    def test_missing_boss_blocks_review_gate(self):
        unit=good()
        unit["boss_stage"]=None
        self.assertIn("boss_metadata_missing",[x["code"] for x in check_unit(unit)["issues"]])
if __name__=="__main__":
    unittest.main()
