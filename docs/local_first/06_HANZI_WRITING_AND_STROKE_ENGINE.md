# Pandarin Local-First — Giai đoạn 5: Luyện viết chữ Hán & Tối ưu hóa Stroke Engine

Tài liệu này ghi nhận kiến trúc, tối ưu hóa hiệu năng, mô hình dữ liệu và kết quả triển khai tính năng Luyện viết chữ Hán (Hanzi Writing) theo chuẩn Local-First cho ứng dụng Pandarin.

---

## 1. Các Vấn đề Tồn đọng Cũ & Giải pháp (AS-IS vs TO-BE)

| Hạng mục | Trước đây (AS-IS) | Sau tối ưu (TO-BE Local-First) |
| :--- | :--- | :--- |
| **Tra cứu 1 chữ Hán (`getCharacterForWritingById`)** | Quét toàn bộ bảng `lexicon_characters` (1.000 dòng), nối chuỗi với toàn bộ từ điển để lấy 1 ký tự $\to$ Giật lag khung hình khi bắt đầu phiên viết. | Kiểm tra `HanziStrokeCache` trước (0ms). Nếu miss, thực hiện câu lệnh SQLite 1 dòng duy nhất (`WHERE c.id = ? LIMIT 1`) với độ trễ $< 1\text{ms}$. |
| **Chuyển chữ kế tiếp (`nextCharacter`)** | Gọi lại `getCharactersForWriting()` không tham số $\to$ tải lại toàn bộ 935 chữ Hán từ database/mạng mỗi lần bấm nút chuyển chữ; không nhớ ngữ cảnh bài học. | Sử dụng chuỗi ký tự theo ngữ cảnh (`characterSequence` từ Unit hoặc HSK). Tra cứu chỉ số trong mảng $O(1)$, hoàn toàn không gọi database/mạng. |
| **Phân tích cú pháp SVG (`SvgStrokeParser`)** | Mỗi lần mở chữ hoặc chuyển vòng phải parse lại chuỗi SVG path thành `Path` đối tượng Flutter. | `HanziStrokeCache` tự động lưu trữ (pre-cache & prefetch) các `Path` đã parse. Khi chuyển chữ, canvas lấy trực tiếp từ cache mà không tốn CPU parse lại. |
| **Lưu tiến độ viết** | Bảng `local_hanzi_progress` trong SQLite bị bỏ quên, kết quả viết không được lưu bền vững khi tắt app. | Khi hoàn thành phiên viết, giao dịch SQLite cập nhật đồng thời: `local_activity_attempts`, `local_hanzi_progress`, `local_xp_events`, `local_study_days`, và đánh dấu `local_stage_progress`. |
| **Luyện viết theo Unit HSK** | Từ Unit Overview (Ải 2 Hanzi), người dùng vào viết chữ nhưng không có danh sách chữ của bài. | Truyền chính xác danh sách ID chữ Hán (`charIds`) và `unitId` vào `HanziWritingScreen`, giúp người học luyện tuần tự tất cả chữ Hán trong bài học đó. |

---

## 2. Mô hình Lưu trữ SQLite Cục bộ (`local_hanzi_progress`)

```sql
CREATE TABLE IF NOT EXISTS local_hanzi_progress (
  local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
  character_id INTEGER NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  best_accuracy REAL NOT NULL DEFAULT 0,
  last_practiced_at_utc TEXT,
  is_mastered INTEGER NOT NULL DEFAULT 0 CHECK(is_mastered IN (0,1)),
  PRIMARY KEY(local_id, character_id)
);
```

### Quy tắc Ghi nhận Tiến độ:
- `attempts`: Cộng dồn số lần người học chạm và vẽ chữ qua các vòng.
- `best_accuracy`: Lấy điểm số cao nhất giữa điểm cũ và lượt làm bài hiện tại (`MAX(best_accuracy, excluded.best_accuracy)`).
- `is_mastered`: Đánh dấu `1` khi điểm số đạt $\ge 90\%$ hoặc chữ Hán đạt điều kiện thành thạo theo luật thưởng.
- `last_practiced_at_utc`: Thời gian UTC kết thúc phiên viết gần nhất.

---

## 3. Kiến trúc Bộ nhớ đệm `HanziStrokeCache`

`HanziStrokeCache` là một singleton in-memory LRU cache phục vụ hai mục đích:
1. **Lưu trữ đối tượng `HanziCharacter`**: Giúp mở lại chữ đã xem tức thì. Tự động bị vô hiệu hóa (`invalidateCharacter`) khi người học hoàn thành bài luyện để cập nhật lại số lần luyện (`practice_count`) và điểm cao nhất (`best_score`).
2. **Lưu trữ danh sách `List<Path>` đã parse**: Tránh việc Flutter dựng lại SVG paths nhiều lần, duy trì tốc độ 60fps trên màn hình viết.
3. **Prefetching**: Khi danh sách chữ Hán của một bài học hoặc cấp độ HSK được tải về, hệ thống tự động tải trước các chữ liền kề để người dùng chuyển chữ mà không bị khựng (0ms lag).

---

## 4. Các File Đã Thay đổi / Thêm mới

| File | Hành động | Mô tả |
| :--- | :--- | :--- |
| `lib/features/hanzi_writing/services/hanzi_stroke_cache.dart` | Tạo mới | LRU Cache cho `Path` và `HanziCharacter`, hỗ trợ prefetching và invalidation. |
| `lib/core/database/app_database.dart` | Cập nhật | Bổ sung `getCharacterById(int id)`, `getCharactersByHskLevel()`, `recordHanziPractice()`, `getHanziProgress()`. |
| `lib/core/database/db_helper.dart` | Cập nhật | Tích hợp `HanziStrokeCache` và tối ưu `getCharacterForWritingById()`, `getCharactersByUnitForWriting()`. |
| `lib/core/learning/data/learning_progress_repository.dart` | Cập nhật | Ghi nhận tiến độ viết vào `local_hanzi_progress` trong giao dịch hoàn thành bài tập (`completeActivity`). |
| `lib/features/hanzi_writing/controller/hanzi_writing_controller.dart` | Cập nhật | Hỗ trợ `characterSequence`, `unitId`, `hskLevel`. Tối ưu `nextCharacter()` tra cứu $O(1)$ không reload catalog. |
| `lib/features/hanzi_writing/screens/hanzi_writing_screen.dart` | Cập nhật | Nhận `characterSequence`, `unitId`, `hskLevel`. Đọc nét vẽ từ `HanziStrokeCache`, chuyển chữ mượt mà. |
| `lib/features/hanzi_writing/screens/hanzi_writing_home_screen.dart` | Cập nhật | Truyền chuỗi ký tự đang lọc và cấp HSK vào `HanziWritingScreen`. |
| `lib/features/unit_overview/page/unit_overview_screen.dart` | Cập nhật | Truyền danh sách `charIds` của Stage 2 vào `HanziWritingScreen`. |
| `test/features/hanzi_writing/hanzi_writing_test.dart` | Tạo mới | 9 ca kiểm thử toàn diện từ SVG parsing, cache prefetch, $O(1)$ sequence đến lưu trữ SQLite và sổ cái XP. |

---

## 5. Kết quả Kiểm thử & Đảm bảo Chất lượng

- `test/features/hanzi_writing/hanzi_writing_test.dart`: **9/9 PASSED**
- `flutter analyze`: **0 Errors, 0 Warnings**
