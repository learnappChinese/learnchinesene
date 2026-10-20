# Pandarin Local-First — Giai đoạn 4: Flashcards & Hệ thống Lặp lại Ngắt quãng (SRS)

Tài liệu này ghi nhận kiến trúc, thuật toán, mô hình dữ liệu và kết quả triển khai tính năng Flashcards và Spaced Repetition System (SRS) theo chuẩn Local-First cho ứng dụng Pandarin.

---

## 1. Mục tiêu và Quyết định Thiết kế

1. **Hoạt động Offline 100%**:
   - Người học có thể mở Flashcards và ôn tập toàn bộ từ vựng đã học hoặc theo cấp độ HSK 1–4 bất kỳ lúc nào mà không cần kết nối Internet hay phụ thuộc Supabase.
   - HSK 5 và HSK 6 được đánh dấu trạng thái "Chưa mở" rõ ràng, thân thiện với người dùng và có tooltip/thông báo giải thích.
2. **Thuật toán Spaced Repetition (SuperMemo SM-2)**:
   - Áp dụng thuật toán SM-2 chuẩn hóa:
     - `Ease Factor (EF)` khởi tạo: $2.5$.
     - Chất lượng phản hồi `q`:
       - `Hard`: $q = 1$ $\to$ Reset chu kỳ ôn tập (`repetitionCount = 0`, `intervalDays = 1`, giảm $EF$, tăng `wrongCount`).
       - `Good`: $q = 4$ $\to$ Tăng chu kỳ ($1 \to 4 \to 4 \times EF \to \dots$).
       - `Easy`: $q = 5$ $\to$ Tăng vọt chu kỳ ($1 \to 6 \to 6 \times EF \to \dots$, tăng $EF$).
     - Giới hạn sàn: $EF \ge 1.3$.
     - Thống kê tự động ghi nhận `isMastered = 1` khi `srsStage >= 4` hoặc `intervalDays >= 21`.
3. **Hiển thị Dynamic Interval Hints trực tiếp trên nút**:
   - Nút "Khó" hiển thị: `1 ngày`.
   - Nút "Vừa" hiển thị chu kỳ tính toán trước (ví dụ: `4 ngày`, `1 tuần`, `1 tháng`).
   - Nút "Dễ" hiển thị chu kỳ nhảy vọt (ví dụ: `6 ngày`, `2 tuần`, `2 tháng`).
4. **Tích hợp Sổ cái Thống kê (Unified Ledger)**:
   - Mỗi phiên Flashcard hoàn thành:
     - Ghi nhận XP hợp lệ vào bảng `local_xp_events` (`action_type = 'flashcard_review'`).
     - Ghi nhận ngày học vào bảng `local_study_days` để duy trì Streak.
     - Cập nhật số từ thuộc, tổng XP vào `local_user_stats`.
5. **Không lưu bộ câu hỏi challenge vào SQLite**:
   - Tuân thủ nguyên tắc: SQLite chỉ lưu trữ từ điển Lexicon (~800 KB). Các câu hỏi, bài luyện được tổng hợp động (synthesize on RAM), đảm bảo ứng dụng siêu nhẹ và nội dung ôn tập luôn biến thiên không trùng lặp nhàm chán.

---

## 2. Lược đồ Cơ sở Dữ liệu Local (`pandarin.db`)

Bảng `local_word_srs` chịu trách nhiệm lưu trạng thái trí nhớ của từng từ vựng:

```sql
CREATE TABLE IF NOT EXISTS local_word_srs (
  word_id INTEGER PRIMARY KEY,
  srs_stage INTEGER NOT NULL DEFAULT 0,
  ease_factor REAL NOT NULL DEFAULT 2.5,
  interval_days INTEGER NOT NULL DEFAULT 1,
  repetition_count INTEGER NOT NULL DEFAULT 0,
  next_review_at TEXT,
  last_reviewed_at TEXT,
  correct_count INTEGER NOT NULL DEFAULT 0,
  wrong_count INTEGER NOT NULL DEFAULT 0,
  is_mastered INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_word_srs_due 
  ON local_word_srs (next_review_at, is_mastered);
```

---

## 3. Các File Đã Triển khai và Cập nhật

| File | Vai trò |
| :--- | :--- |
| `lib/core/learning/service/spaced_repetition_service.dart` | Service thuần túy cài đặt thuật toán SM-2, tính toán ngày ôn tập kế tiếp, trạng thái Mastered và chuỗi định dạng gợi ý `getIntervalHint`. |
| `lib/core/database/app_database.dart` | Bổ sung các phương thức SQLite tốc độ cao: `getWordsByHskLevel`, `getDueSrsWords`, `getWordSrsState`, `recordWordSrsRating`, `recordFlashcardSessionCompleted`. |
| `lib/core/database/db_helper.dart` | Cập nhật `getReviewWords({int limit = 30})` truy vấn trực tiếp các từ đến hạn ôn tập; `upsertProgress` hỗ trợ tham số `SrsRating`. |
| `lib/features/flashcards/controller/flashcards_controller.dart` | Quản lý vòng đời bộ thẻ: tải thẻ theo HSK (1 query đơn), đánh giá theo SM-2, tính XP hoàn thành phiên và cập nhật streak. |
| `lib/features/flashcards/flashcards_screen.dart` | Giao diện Flashcards lật 3D, filter chips HSK 1–6 (khóa 5–6), nhãn gợi ý thời gian dynamic trên nút Khó/Vừa/Dễ. |
| `lib/features/flashcards/widget/flashcard_content.dart` | Màn hình `FlashcardCompletion` đẹp mắt với huy hiệu thống kê (số thẻ ôn, độ chính xác %, XP nhận được) và nút quay về Trang chủ. |
| `test/features/flashcards/flashcard_srs_test.dart` | 13 ca kiểm thử toàn diện từ công thức SM-2 toán học đến tích hợp SQLite local. |

---

## 4. Kết quả Kiểm thử & Đảm bảo Chất lượng

- `test/features/flashcards/flashcard_srs_test.dart`: **13/13 PASSED**
- `test/screen/controllers/screen_async_workflows_test.dart`: **17/17 PASSED**
- `test/core/database/app_database_test.dart`: **10/10 PASSED**
- `test/core/database/local_guest_migration_service_test.dart`: **4/4 PASSED**
- `test/core/database/offline_boot_test.dart`: **6/6 PASSED**
- `test/core/learning/guest_learning_progression_test.dart`: **12/12 PASSED**
- `test/core/learning/local_hsk_curriculum_mapping_test.dart`: **7/7 PASSED**
- `flutter analyze`: **0 Errors, 0 Warnings** (Chỉ còn các thông báo lint `info` đã có từ trước của repository).
