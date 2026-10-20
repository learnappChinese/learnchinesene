# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 05. CƠ SỞ DỮ LIỆU VÀ SUPABASE SCHEMA (DATABASE SCHEMA & POLICIES)

> **Cơ sở dữ liệu**: PostgreSQL trên nền tảng Supabase (`https://hrlahralknhijnkypjix.supabase.co`).  
> **Căn cứ xác minh**: 21 migration files trong `supabase/migrations/`, schema SQL ban đầu `schema.txt`, code xử lý trong `lib/core/database/` và các models tương ứng.

---

### 1. Bảng phân loại Nguồn gốc Schema (Verification Status)

- **[ĐÃ XÁC MINH TRỰC TIẾP TỪ MIGRATION]**: Bảng, cột, chỉ mục, ràng buộc CHECK và hàm RPC được định nghĩa tường minh trong các tệp SQL của repository.
- **[SUY LUẬN TỪ CODE VÀ TRUY VẤN FLUTTER]**: Các bảng giáo trình tĩnh được tạo lập từ trước qua console hoặc import script (`lexicon_*`), được chứng minh bằng các câu lệnh `select()` thực tế trong `db_helper.dart` và `duo_db_helper.dart`.

---

### 2. Danh mục Bảng dữ liệu chi tiết (Tables & Columns)

#### A. Phân hệ Giáo trình & Từ vựng tĩnh (Lexicon Curriculum)

##### 1. Bảng `lexicon_hsk_levels`
- **Mục đích**: Danh mục 6 cấp độ HSK chuẩn (HSK 1 đến HSK 6).
- **Cấu trúc**:
  - `id` (INTEGER, PK): Mã cấp độ (1 đến 6).
  - `name` (TEXT, NOT NULL): Tên hiển thị (ví dụ: 'HSK 1', 'HSK 2').
  - `sort_order` (INTEGER): Thứ tự sắp xếp hiển thị.
- **Quan hệ**: 1 - N với `lexicon_units`.

##### 2. Bảng `lexicon_units`
- **Mục đích**: Các bài học thuộc từng cấp độ HSK.
- **Cấu trúc**:
  - `id` (INTEGER, PK): Khóa chính tự tăng.
  - `hsk_level_id` (INTEGER, FK -> `lexicon_hsk_levels.id`): Cấp độ HSK trực thuộc.
  - `title` (TEXT, NOT NULL): Tiêu đề bài học (ví dụ: 'Chào hỏi', 'Gia đình').
  - `unit_number` (INTEGER): Số thứ tự bài học.
  - `sort_order` (INTEGER): Thứ tự sắp xếp.

##### 3. Bảng `lexicon_words`
- **Mục đích**: Kho từ vựng tiếng Trung trung tâm của toàn bộ ứng dụng.
- **Cấu trúc**:
  - `id` (INTEGER, PK): ID từ vựng.
  - `word` (TEXT, NOT NULL): Chữ Hán giản thể (ví dụ: '你好', '学习').
  - `pinyin` (TEXT, NOT NULL): Phiên âm kèm dấu thanh điệu (ví dụ: 'nǐ hǎo').
  - `meaning_vi` (TEXT, NOT NULL): Nghĩa tiếng Việt.
  - `meaning_en` (TEXT): Nghĩa tiếng Anh.
  - `tts_url` (TEXT): Đường dẫn URL tới file âm thanh phát âm bản xứ (MP3).
  - `hsk_level_id` (INTEGER, FK -> `lexicon_hsk_levels.id`): Cấp độ từ vựng.
  - `main_character_id` (INTEGER, FK -> `lexicon_characters.id`): Liên kết tới chữ Hán chính để tập viết.

##### 4. Bảng `lexicon_examples`
- **Mục đích**: Các câu ví dụ và câu thoại minh họa cho từ vựng và bài học.
- **Cấu trúc**:
  - `id` (INTEGER, PK): Khóa chính câu ví dụ.
  - `word_id` (INTEGER, FK -> `lexicon_words.id`): Từ vựng trọng tâm trong câu.
  - `unit_id` (INTEGER, FK -> `lexicon_units.id`): Bài học ngữ cảnh.
  - `sentence_cn` (TEXT, NOT NULL): Câu tiếng Trung giản thể.
  - `sentence_pinyin` (TEXT, NOT NULL): Phiên âm Pinyin toàn câu.
  - `sentence_vi` (TEXT, NOT NULL): Bản dịch nghĩa tiếng Việt.
  - `example_order` (INTEGER): Thứ tự sắp xếp trong đoạn hội thoại.

##### 5. Bảng `lexicon_characters`
- **Mục đích**: Dữ liệu hình học phục vụ tính năng Luyện viết chữ Hán theo nét bút thuận.
- **Cấu trúc**:
  - `id` (INTEGER, PK): ID chữ Hán.
  - `character` (TEXT, NOT NULL): Ký tự chữ Hán đơn lẻ (ví dụ: '你').
  - `stroke_count` (INTEGER, NOT NULL): Tổng số nét.
  - `stroke_width` (DOUBLE PRECISION): Chiều rộng khung canvas thiết kế.
  - `stroke_height` (DOUBLE PRECISION): Chiều cao khung canvas thiết kế.
  - `stroke_paths` (TEXT, NOT NULL): Chuỗi JSON hoặc danh sách thẻ SVG Path chứa tọa độ vector của từng nét bút.

---

#### B. Phân hệ Lộ trình Gamification & Duo (Duo Curriculum)

##### 6. Các bảng cấu trúc bài học Duo (`courses`, `sections`, `units`, `levels`, `sessions`)
- **Nguồn gốc**: Di chuyển từ SQLite sang PostgreSQL.
- **Cấu trúc liên kết**:
  - `courses` (`id` TEXT PK, `title`, `from_language`, `learning_language`)
  - `sections` (`id` TEXT PK, `course_id` FK, `section_number` INT, `title` TEXT)
  - `units` (`id` TEXT PK, `section_id` FK, `unit_number` INT, `unit_index` INT, `title` TEXT)
  - `levels` (`id` TEXT PK, `unit_id` FK, `level_type` TEXT, `skill_id` TEXT, `level_index` INT, `teaching_objective` TEXT)
  - `sessions` (`id` INT PK, `level_id` TEXT FK, `level_session_index` INT, `duolingo_session_id` TEXT UNIQUE)

##### 7. Bảng `challenges` (Kho câu hỏi tương tác Duo)
- **Cấu trúc**:
  - `id` (TEXT, PK): Mã định danh thử thách.
  - `session_id` (INTEGER, FK -> `sessions.id` ON DELETE CASCADE).
  - `type` (TEXT, NOT NULL): Loại câu hỏi (`select_answer`, `translate`, `gap_fill`, `tap_complete`, `sentence_order`, `word_connect`, `match_pairs`, `listen_select`, `dialogue`, `learn_words`, `speaking`).
  - `prompt` (TEXT): Đề bài hiển thị.
  - `tts` (TEXT): URL file âm thanh của đề bài.
  - `tokens_text`, `tokens_tts`, `tokens_hints` (TEXT / JSON Array): Mảng từ khóa, URL phát âm từng từ và gợi ý dịch nghĩa.
  - `choices_text`, `choices_tts`, `choices_correct` (TEXT / JSON Array): Mảng các phương án lựa chọn và vector đúng/sai (ví dụ: `[1, 0, 0, 0]`).
  - `solutions` (TEXT / JSON Array): Mảng các đáp án được chấp nhận khi ghép câu hoặc dịch thuật.

##### 8. Bảng `duo_active_sessions` (Phiên làm bài dở dang)
- **Định nghĩa**: Migration `20261006_duo_cloud_progress.sql`.
- **Cấu trúc**:
  - `user_id` (UUID, NOT NULL, FK -> `auth.users.id`).
  - `game_id` (BIGINT, NOT NULL, FK -> `duo_game_definitions.id`).
  - `level_id` (TEXT, NOT NULL, FK -> `duo_levels.id`).
  - `current_index` (INT, DEFAULT 0, CHECK >= 0): Câu hỏi hiện tại đang dừng.
  - `score` (INT, DEFAULT 0, CHECK >= 0): Điểm số tích lũy tạm thời.
  - `correct_count`, `wrong_count` (INT, DEFAULT 0): Số câu đúng/sai trong phiên.
  - `attempt_id` (TEXT): ID của lượt làm bài.
  - `status` (TEXT, CHECK in `'active'`, `'completed'`, `'abandoned'`).
  - `PK (user_id, game_id, level_id)`.

---

#### C. Phân hệ Tiến trình, Sổ cái XP & Thống kê Người dùng (Authoritative Ledger)

##### 9. Bảng `learning_attempts` (Lịch sử lượt làm bài chi tiết)
- **Định nghĩa**: Migration `20261008_unified_learning_reward_system.sql` & `20261009014720_unified_learning_pipeline_v2.sql`.
- **Cấu trúc**:
  - `id` (TEXT, PK): Khóa chính định danh attempt (tạo từ client, format: `act_timestamp`).
  - `user_id` (UUID, NOT NULL, FK -> `auth.users.id` ON DELETE CASCADE).
  - `activity_type` (TEXT, NOT NULL): `'vocabulary'`, `'listening'`, `'speaking'`, `'hanzi'`, `'dialogue'`, `'boss'`, `'review'`, `'game_mission'`.
  - `source_type` (TEXT, NOT NULL): `'level'`, `'word'`, `'boss'`, `'mini_game'`, v.v.
  - `source_id` (TEXT, NOT NULL): ID của thực thể gốc (ví dụ: level ID, character ID, stage ID).
  - `level_id` (TEXT, NULLABLE): Liên kết tới level bài học.
  - `unit_id` (TEXT, NULLABLE): Liên kết tới unit bài học.
  - `started_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()).
  - `completed_at` (TIMESTAMPTZ, NULLABLE): Thời điểm kết thúc.
  - `status` (TEXT, NOT NULL, CHECK in `'started'`, `'passed'`, `'failed'`, `'abandoned'`).
  - `score`, `accuracy` (DOUBLE PRECISION): Điểm số và tỷ lệ đúng (0.0 đến 1.0).
  - `correct_count`, `wrong_count` (INTEGER): Thống kê số lượng câu đúng/sai.
  - `duration_seconds` (INTEGER, CHECK >= 0): Thời gian làm bài tính bằng giây.
  - `best_combo` (INTEGER, CHECK >= 0): Chuỗi đúng dài nhất.
  - `stars` (SMALLINT, CHECK between 0 and 3): Số sao đạt được.
  - `xp_earned` (INTEGER, CHECK >= 0): Số XP nhận được trong attempt này.
  - `mastery_before`, `mastery_after` (DOUBLE PRECISION, CHECK between 0 and 1): Trình độ bài học trước và sau lượt làm.
  - `first_clear` (BOOLEAN, DEFAULT false): Đánh dấu lần đầu tiên vượt qua ải.
  - `perfect` (BOOLEAN, DEFAULT false): Đánh dấu đạt độ chính xác 100%.
  - `metadata` (JSONB, DEFAULT '{}'): Dữ liệu ngữ cảnh bổ sung.
- **Chỉ mục (Indexes)**:
  - `idx_learning_attempts_user_created` trên `(user_id, created_at desc)`.
  - `idx_learning_attempts_user_source_status` trên `(user_id, source_type, source_id, status)`.
  - `idx_learning_attempts_user_unit_activity` trên `(user_id, unit_id, activity_type, completed_at desc)`.

##### 10. Bảng `learning_xp_events` (Sổ cái giao dịch XP bất biến - Immutable XP Ledger)
- **Định nghĩa**: Migration `20261008_unified_learning_reward_system.sql` & `20261009014720_unified_learning_pipeline_v2.sql`.
- **Cấu trúc**:
  - `id` (BIGSERIAL, PK): Mã giao dịch.
  - `user_id` (UUID, NOT NULL, FK -> `auth.users.id` ON DELETE CASCADE).
  - `source_type`, `source_id`, `activity_type` (TEXT, NOT NULL).
  - `xp_amount` (INTEGER, NOT NULL, CHECK >= 0): Lượng XP thực nhận.
  - `base_xp` (INTEGER, DEFAULT 0): Điểm XP cơ bản của hoạt động.
  - `bonus_xp` (INTEGER, DEFAULT 0): Điểm thưởng thêm (combo, first clear, perfect).
  - `reason` (TEXT): Lý do cấp thưởng (ví dụ: `'activity_passed'`, `'first_clear_bonus'`).
  - `event_key` (TEXT, NOT NULL): Khóa chống trùng lặp (Idempotency Key).
  - `attempt_id` (TEXT, NULLABLE): Liên kết tới bản ghi attempt tương ứng.
  - `created_at` (TIMESTAMPTZ, DEFAULT now()).
- **Ràng buộc duy nhất**: `UNIQUE (user_id, event_key)`. Chống việc gửi lại kết quả nhiều lần để farm điểm XP.

##### 11. Bảng `app_user_stats` (Chỉ số tổng hợp của Người dùng)
- **Cấu trúc**:
  - `user_id` (UUID, PK, FK -> `auth.users.id`).
  - `total_exp` (INTEGER, DEFAULT 0): Tổng điểm kinh nghiệm tích lũy trọn đời.
  - `current_streak` (INTEGER, DEFAULT 0): Chuỗi ngày học liên tục hiện tại.
  - `total_words_mastered` (INTEGER, DEFAULT 0): Tổng số từ vựng đã tinh thông.
  - `total_favorites` (INTEGER, DEFAULT 0): Số mục yêu thích.
  - `last_study_date` (DATE): Ngày học gần nhất (theo múi giờ `Asia/Ho_Chi_Minh`).

##### 12. Bảng `app_user_entitlements` & `ai_usage_quotas` (Bảo mật & Quota AI)
- **Định nghĩa**: Migration `20261011180000_secure_entitlements_and_ai_quotas.sql`.
- `app_user_entitlements`: Quản lý thuê bao người dùng đã được xác minh chống gian lận.
- `ai_usage_quotas`: Theo dõi số lượt gọi (`request_count`) và số token tiêu thụ (`token_count`) của từng user theo ngày (`usage_date`).

---

### 3. Các Stored Procedures & RPC Cốt lõi

| Tên RPC | Quyền thực thi | Tham số chính | Vai trò kỹ thuật |
| :--- | :--- | :--- | :--- |
| **`complete_learning_activity_v2`** | `SECURITY DEFINER` (enforces `auth.uid() == p_user_id`) | `p_user_id`, `p_activity_type`, `p_source_type`, `p_source_id`, `p_unit_id`, `p_level_id`, `p_score`, `p_accuracy`, `p_duration_seconds`, `p_attempt_id`, `p_metadata` | **Trọng tài thưởng máy chủ**: Tính sao, tính XP, kiểm tra idempotency, ghi `learning_attempts`, ghi `learning_xp_events`, cập nhật streak trong `app_user_stats`, tính `unit_mastery`, mở khóa `nextNodeId` và `bossReady`. |
| **`start_learning_attempt_v2`** | `SECURITY DEFINER` | `p_attempt_id`, `p_activity_type`, `p_source_type`, `p_source_id`, `p_unit_id`, `p_level_id`, `p_metadata` | Ghi nhận bắt đầu một phiên làm bài với trạng thái `'started'`. |
| **`abandon_learning_attempt_v2`** | `SECURITY DEFINER` | `p_attempt_id`, `p_metadata` | Đánh dấu phiên làm bài bị huỷ `'abandoned'` khi người dùng thoát giữa chừng. |
| **`unit_learning_path_v2`** | `SECURITY INVOKER` | `p_unit_id` | Trả về cấu trúc toàn bộ ải của bài học kèm trạng thái khóa, mở khóa, hoàn thành, điểm cao nhất, số sao và cổng Boss. |
| **`unit_mastery_v2`** | `SECURITY INVOKER` | `p_unit_id` | Tính toán tỷ lệ thông thạo 4 kỹ năng (`vocabulary`, `listening`, `speaking`, `hanzi`) có trọng số: Từ vựng 35%, Nghe 25%, Nói 20%, Viết 20%. |
| **`current_learning_unit_v2`** | `SECURITY INVOKER` | Không | Xác định bài học hiện tại người dùng đang học để hiển thị lên Home Hero Card. |
| **`learning_sections_v2`** | `SECURITY INVOKER` | Không | Trả về danh sách Phần học (Sections) kèm tiến độ hoàn thành. |
| **`learning_units_v2`** | `SECURITY INVOKER` | `p_section_id` | Trả về danh sách Bài học (Units) trong một phần kèm trạng thái mở khóa. |
| **`record_word_progress`** | `SECURITY INVOKER` | `p_word_id`, `p_is_correct`, `p_level` | Cập nhật tiến độ Spaced Repetition (SRS) của một từ vựng trong bảng `lexicon_user_progress`. |
| **`check_and_increment_ai_quota`** | `SECURITY DEFINER` | `p_user_id`, `p_tokens` | Kiểm tra giới hạn gọi AI trong ngày của người dùng từ Supabase Edge Function. |

---

### 4. Đánh giá Chính sách Bảo mật (Row Level Security - RLS)

- **Các bảng công khai đọc (Public Read-Only)**: `lexicon_hsk_levels`, `lexicon_units`, `lexicon_topics`, `lexicon_words`, `lexicon_examples`, `lexicon_characters`, `courses`, `sections`, `units`, `levels`, `challenges`, `duo_game_definitions`. Bật RLS cho phép `anon` và `authenticated` SELECT thoải mái; chặn hoàn toàn thao tác INSERT/UPDATE/DELETE từ client.
- **Các bảng dữ liệu người dùng (User-Scoped)**:
  - `learning_attempts`: RLS chính sách `auth.uid() = user_id`. Client chỉ được SELECT và INSERT bản ghi của chính mình.
  - `learning_xp_events`: RLS chính sách `auth.uid() = user_id`. Client chỉ được SELECT; các thao tác ghi được chuyển giao an toàn thông qua RPC `complete_learning_activity_v2`.
  - `app_user_entitlements` & `ai_usage_quotas`: RLS chính sách SELECT own row. Lệnh `REVOKE INSERT, UPDATE, DELETE FROM authenticated, anon` đảm bảo tuyệt đối không có lỗ hổng tự cấp bản quyền hoặc reset quota từ client.
