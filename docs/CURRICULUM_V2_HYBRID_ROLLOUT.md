# Curriculum V2 — triển khai kết hợp, không phá chương trình học đang chạy

## Mục tiêu
Giữ nguyên 310 `duo_units`, 64.828 `duo_challenges`, 2.205 `lexicon_words`, tất cả user XP, SRS, mastery, Guest và Boss; bổ sung chương trình học có phiên bản. Bài mới sử dụng chính legacy IDs, người học vẫn chơi theo World → Section → Unit → Mission → Boss.

**Trạng thái:** PR hạ tầng nháp. Migration trong nhánh này **chưa được deploy**. Các bảng mới mặc định private, không tự kích hoạt/chuyển hướng Flutter.

## Quy trình chuyển 1 Unit (không đổi format)
1. Chọn `sec_1_unit_1` làm pilot. Chụp snapshot challenge IDs, answers, word IDs, game codes, required mission graph, Boss ID, thời gian đọc data và event XP/unlock.
2. Tạo `learning_curriculum_versions` version `curriculum-v2-pilot`, trạng thái `draft`.
3. Viết `learning_unit_plans_v2` gắn cùng `legacy_unit_id` với **mục tiêu giao tiếp và bài dạy** trong `lesson_plan`. JSON: `phases` (preview, comprehension, retrieval, listening, production, checkpoint, review), `estimated_minutes`, `grammar_points`, `pass_policy`; không copy/chế đáp án trong JSON.
4. Map từ và challenge đã tồn tại vào `learning_unit_content_v2`. Cột `content_kind` = word hoặc challenge; `content_id` giữ nguyên ID trong lexicon/duo_challenges. Kiểm tra tồn tại, Unit scope và duplicate trong validator trước review. Không chuyển toàn bộ challenge sang 1 game.
5. Dùng validator xuất báo cáo: missing word/pinyin/translation, answer schema theo loại challenge, distractor hợp lệ, TTS audio URL có thực, nguồn HSK, số câu unique, kỹ năng theo loại, Boss prerequisites và content coverage. Cột null có thể hợp lệ theo challenge `type`; validator phải đọc fields JSON đặc thù.
6. Reviewer duyệt `quality_status=approved` cho Unit đã đạt tất cả tiêu chí. Không kích hoạt tự động.
7. Chạy A/B hoặc flag riêng trên Guest test profile / Supabase staging (cần quyền/chi phí Supabase branch được chấp thuận riêng). Flutter adapter `CurriculumRepository` chọn v1 fallback hoặc v2 theo feature flag và Unit whitelist, không dùng `learning_unit_plans_v2` làm nguồn XP/unlock.
8. Test end-to-end Stage1 → Stage2 → Boss → Next Unit, Guest relaunch, signed-in RPC, Guest→Cloud migration, replay double submit XP, offline retry, SRS. Compare screenshot + challenge order / score / content coverage.
9. Rollout Unit 1 cho canary rồi lần lượt từng Unit; rollback flag về legacy nếu có regression. `legacy_unit_id` và mọi progress IDs giữ nguyên xuyên rollout.
10. Chỉ khi đã verified > nhiều Unit và metrics cải thiện mới xem xét refactor vật lý bảng. Không DROP trong giai đoạn này.

## Định nghĩa bài học mới
- **Preview**: chữ Hán, pinyin, tiếng Việt, âm chuẩn, mẫu câu.
- **Comprehension**: nhận diện nghĩa và ý câu.
- **Retrieval**: gợi nhớ không lộ đáp án trước.
- **Listening**: nghe hiểu/tone với rubric tin cậy.
- **Production**: sắp câu hoặc dùng từ vào ngữ cảnh.
- **Hanzi/Speaking**: optional khi device capability không hỗ trợ; không fake pass.
- **Checkpoint**: câu hỏi tổng hợp có bằng chứng mastery; Boss chỉ mở theo gate hiện hành.
- **Review**: đưa từ được học đúng vào SRS, không tự gán mastery khi mới xem thẻ từ.

## Chiến lược dữ liệu, performance, bảo mật
- Giữ bảng normalized source; đưa nội dung từng Unit qua 1 RPC đọc gộp/pagination + cache theo content version. PR #25 `learning_unit_bundle_v1` là phần nền, **chưa merge**.
- Không bundle user-state XP/attempts/mastery cùng static content cache; tiến độ theo identity/sync riêng.
- Đo p50/p95 theo device/network, request count, response bytes. Không dùng mục tiêu “càng ít bảng càng tốt” như tiêu chí thành công.
- Private v2 draft tables: RLS on, no client grants. Chỉ cấp API an toàn sau review; không cấp service_role cho Flutter.
- Tránh schema/RPC dùng SECURITY DEFINER không rõ quyền. Không xóa legacy schema khi còn client phiên bản cũ.
- Supabase migration phải check schema history / stage environment trước áp dụng; lưu backup và rollback script; không deploy trên production chưa qua test.

## Definition of Done theo giai đoạn
| Batch | Phạm vi | Điều kiện pass |
|---|---|---|
| PR-C0 | schema private staging + roadmap | SQL review, migration chạy trên staging, quyền bảo mật đúng; không thay người dùng |
| PR-C1 | validator + content audit | báo cáo theo Unit, lỗi ưu tiên, có sample evidence |
| PR-C2 | Unit 1 lesson_plan + mapping | 100% ID tham chiếu tồn tại, nội dung HSK phù hợp, reviewer approved |
| PR-C3 | Flutter adapter + read model | cờ tắt fallback v1; bật trên test user Unit1 load v2 đúng |
| PR-C4 | runtime QA + canary rollout | Stage → Boss → Next Unit, XP/migration/SRS pass thật |
| PR-C5 | rollout Unit 2–10 rồi 11–310 | per Unit review + metrics, rollback từng Unit |

## Trường hợp phải dừng
- ID Unit hoặc challenge đổi mà không có backward mapping.
- Guest path không mở khóa đúng, Boss gate sai hoặc XP cộng trùng.
- TTS/answer bị suy đoán, sai chữ Hán/pinyin, đề thi thiếu nguồn.
- RPC tăng latency/payload so với trước mà không có lợi ích học tập.
- Thiếu backup, staging, CI hoặc review nhưng muốn deploy all 310 Units.

## Lệnh kiểm tra thực tế tại máy Windows
```powershell
cd D:\Projects\Flutter_Project\learnchinesene
git fetch origin
git switch hieu
git pull --ff-only origin hieu
flutter pub get
flutter analyze
flutter test
flutter run -t lib/main.dart
```
Dừng và xử lý nếu working tree dirty, không reset mất thay đổi người dùng. Khi PR-C0 review xong, triển khai migration staging trước, **không kích hoạt v2 cho user**.
