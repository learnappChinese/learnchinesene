# PANDARIN LOCAL-FIRST ARCHITECTURE
## 00. AS-IS GAPS & ARCHITECTURAL DECISIONS

> **Dự án**: Pandarin — Nền tảng học tiếng Trung & HSK Local-First  
> **Ngày lập**: 2026-10-20  
> **Trạng thái**: Đã đối chiếu mã nguồn thực tế và Supabase production read-only.

---

### 1. Đối chiếu Thực tế Mã nguồn vs Báo cáo Kiểm toán cũ

Quá trình kiểm tra thực tế mã nguồn tại `lib/` và truy vấn trực tiếp cơ sở dữ liệu Supabase `hrlahralknhijnkypjix` đã làm rõ các sai lệch trong các báo cáo kiểm toán trước đó:

| Hạng mục | Báo cáo kiểm toán cũ nêu | Thực tế mã nguồn & CSDL | Quyết định kỹ thuật |
| :--- | :--- | :--- | :--- |
| **Đường dẫn DbHelper** | `lib/core/services/db_helper.dart` | [`lib/core/database/db_helper.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/database/db_helper.dart) | Sử dụng đường dẫn chuẩn `lib/core/database/`. |
| **Đường dẫn Hanzi Writing** | `lib/features/tools/hanzi_writing_screen.dart` | [`lib/features/hanzi_writing/`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/hanzi_writing/) | Module độc lập tại `lib/features/hanzi_writing/`. |
| **Đường dẫn Review/Flashcards** | `lib/features/review/` | Tồn tại cả [`lib/features/review/`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/review/) và [`lib/features/flashcards/`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/flashcards/) | Hợp nhất luồng Flashcards/SRS xoay quanh SQLite cục bộ. |
| **Bảng liên kết từ vựng - Unit** | `lexicon_word_units` | `lexicon_word_sources` (4.052 dòng) | Dùng `lexicon_word_sources` với các cột `word_id, unit_id, topic_id`. |
| **Số lượng cấp độ HSK** | Giả định HSK 1-6 | Chỉ có HSK 1-4 (4 dòng trong `lexicon_hsk_levels`) | Không tạo HSK 5-6 giả; hiển thị HSK 1-4 hợp lệ. |
| **Cấu trúc Lộ trình Duo** | Giả định `duo_sections` tương đương HSK | `duo_sections` có 8 dòng mang tên `Path Section 0-7` | Tách biệt hoàn toàn Lộ trình Duo và Giáo trình HSK; không force-join tự động. |
| **Khởi động ứng dụng** | Treo timeout 15 giây nếu không có mạng | `AppBootstrap` trong `lib/main.dart` ném ngoại lệ chặn UI | Loại bỏ hoàn toàn sự phụ thuộc mạng trong bootstrap. |

---

### 2. Các Lỗ hổng Trọng yếu của Hệ thống Hiện tại (As-Is Gaps)

1. **Khóa mạng khi khởi động (Network-Gated Startup)**:
   - `main.dart` gọi `SupabaseBootstrap.initialize().timeout(15s)`. Mất mạng dẫn đến màn hình lỗi `_CloudErrorView`, người dùng không thể vào học.
2. **Yêu cầu Auth trong luồng học (Auth-Gated Progress)**:
   - `SplashController` gọi `auth.continueAsGuest()`.
   - `DbHelper.getReviewWords()` và nhiều hàm DAO từ chối phục vụ nếu `currentUser == null`.
3. **Mất dữ liệu và bất ổn định ở Chế độ Khách (Guest Fragility)**:
   - Tiến độ học của Khách nằm rải rác trên `SharedPreferences` dạng JSON không chuẩn hóa (`guest_learning_completed_stages_v1`, `guest_learning_xp_events_v2`).
   - Nguy cơ mất toàn bộ dữ liệu khi xóa cache hoặc cập nhật app.
4. **Hiệu năng Luyện viết Chữ Hán (Hanzi Writing Bottleneck)**:
   - `HanziWritingController` nạp lại toàn bộ từ điển (2.205 từ) trên mỗi ký tự chuyển tiếp.
5. **AI Module gây phân tán và rủi ro chi phí API**:
   - Tích hợp Gemini API trực tiếp trong lộ trình học làm phân tán trải nghiệm cốt lõi và phát sinh lỗi khi không có mạng.

---

### 3. Các Quyết định Kiến trúc Cốt lõi (Architectural Decisions)

#### Quyết định 1: SQLite trên thiết bị là Nguồn Sự thật Duy nhất (Single Source of Truth)
- Sử dụng package `sqflite` (và `sqflite_common_ffi` cho môi trường kiểm thử/desktop).
- Toàn bộ dữ liệu người học (attempts, stage progress, word SRS, hanzi writing, XP events, study days, active sessions) được lưu trong database `pandarin.db` trên thiết bị.
- Đảm bảo tính toàn vẹn dữ liệu với `PRAGMA foreign_keys = ON;`.

#### Quyết định 2: Khởi động Hoàn toàn Ngoại tuyến (Offline-First Boot)
- `AppBootstrap` và `SplashController` ưu tiên khởi tạo `AppDatabase` cục bộ trước.
- Kết nối Supabase chuyển sang chế độ bất đồng bộ không chặn (Non-blocking / Background). Mất mạng không bao giờ cản trở mở app.

#### Quyết định 3: Danh tính Người học Cục bộ (Local Identity Contract)
- Khởi tạo `local_profiles` với một UUID ngẫu nhiên duy nhất trên thiết bị (`local_id`).
- Xóa bỏ hoàn toàn luồng Login/Register/Social Sign-in ở giao diện người dùng. Không phụ thuộc vào `auth.users.id`.

#### Quyết định 4: Đóng gói Sẵn Giáo trình Cốt lõi HSK 1-4 (Bundled Seed Content)
- Trích xuất dữ liệu thực tế từ Supabase thành gói giáo trình chuẩn `assets/data/hsk_curriculum_pack_v1.json`.
- Tự động nạp vào SQLite khi mở app lần đầu, đảm bảo 100% nội dung HSK 1-4, từ vựng, chữ Hán và nét viết khả dụng ngay cả ở chế độ máy bay.

#### Quyết định 5: Bảo tồn Nguyên vẹn Dữ liệu Khách Cũ (Non-Destructive Migration)
- Quét các key SharedPreferences cũ (`guest_learning_*`) và nạp chuyển đổi vào SQLite bằng giao dịch an toàn (idempotent transaction).
- **Tuyệt đối không xóa key SharedPreferences cũ** cho đến khi migration hoàn tất và được xác thực.

#### Quyết định 6: Ẩn Toàn bộ Bề mặt Tính năng AI (AI Surfaces Default-OFF)
- Đưa toàn bộ các route, tab, nút bấm AI (Gemini Chat, AI Dict, Thi thử HSK AI) về trạng thái ẩn/vô hiệu hóa ở bản phát hành.
- Giữ nguyên mã nguồn AI trong codebase để tái kích hoạt trong tương lai.

#### Quyết định 7: Giao dịch Học tập Nguyên tử (Atomic Learning Transaction)
- Một lượt hoàn thành bài học, luyện viết hay ôn flashcard thực thi trong 1 transaction duy nhất:
  `Ghi Attempt` → `Cập nhật Stage/SRS/Hanzi Progress` → `Cộng XP với Event Key duy nhất` → `Ghi nhận Study Day` → `Commit` → `Phát thông báo Sync UI`.
- Ngăn chặn hoàn toàn lỗi cộng trùng XP (Double XP) và mất đồng bộ tiến độ.
