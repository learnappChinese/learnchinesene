# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 00. TỔNG QUAN HỆ THỐNG VÀ VẤN ĐỀ CHÍNH (EXECUTIVE SUMMARY)

> **Dự án**: Pandarin (HSK Chinese Learning App)  
> **Repository Path**: `d:\Projects\Flutter_Project\learnchinesene`  
> **Thời điểm kiểm toán**: Tháng 10/2026 (Base commit `e6d6f6b` - Merge PR #24 `huunam/update_ui`)  
> **Phương pháp**: Reverse Engineering tĩnh mã nguồn Flutter (`lib/`), migrations Supabase (`supabase/migrations/`), Edge Functions (`supabase/functions/`), tài liệu kỹ thuật (`docs/`) và đối chiếu luồng dữ liệu thực tế (AS-IS).  
> **Nguyên tắc**: Read First — Analyze Second — Recommend Last. Không can thiệp source code, không migration, không sửa database.

---

### 1. Bản chất hệ thống và hiện trạng vận hành thực tế

Ứng dụng **Pandarin** là một giải pháp học tiếng Trung và luyện thi HSK kết hợp yếu tố nhập vai kỳ ảo (Chinese Fantasy Adventure), gamification (Duo-style learning stages, Boss Battle, mini-games) và trợ lý trí tuệ nhân tạo (Gemini AI Gateway).

Hệ thống được thiết kế theo mô hình **Cloud-First & Server-Authoritative** với Supabase làm backend cốt lõi:
1. **Dữ liệu tĩnh & giáo trình**: Các cấp độ HSK, đơn vị bài học (Units), từ vựng (Words), câu ví dụ (Examples), chữ Hán (Characters) và các thử thách màn chơi (Challenges) được lưu trữ hoàn toàn trên các bảng Postgres của Supabase (`lexicon_*` và `duo_*`).
2. **Tiến trình người dùng (Signed-in)**: Máy chủ nắm toàn quyền quyết định (Server-Authoritative). Điểm kinh nghiệm (XP), chuỗi ngày học (Streak), độ thông thạo kỹ năng (Mastery), trạng thái mở khóa màn chơi (`nextNodeId`) và mở cổng Boss (`bossReady`) được tính toán và cập nhật nguyên tử thông qua Stored Procedure PL/pgSQL `complete_learning_activity_v2`.
3. **Tiến trình khách vãng lai (Guest Mode)**: Sau PR #24 (`huunam/update_ui`), toàn bộ màn hình Auth (Login, Register, Welcome) đã được gỡ bỏ khỏi luồng khởi động chính. Ứng dụng **luôn đăng nhập thẳng dưới danh nghĩa Guest (`Khách lãng du`)** tại `SplashController` qua `auth.continueAsGuest()`. Mọi tiến trình của khách được lưu cục bộ thông qua `GuestLearningProgressStore` trong `SharedPreferences` và được tính toán độc lập bởi `GuestJourneyResolver`.
4. **Đồng bộ hóa đa mô-đun (Cross-Module Sync)**: Sau PR 01, hệ thống sở hữu cơ chế điều phối vô hiệu hóa bộ nhớ đệm tập trung `LearningProgressSyncService`. Mỗi khi hoàn thành một hoạt động học tập, một sự kiện miền định kiểu (`LearningDomainEvent`) được phát ra để 9 chủ sở hữu trạng thái (`HomeController`, `UnitOverviewController`, `ReviewController`, `ProfilePage`, v.v.) tự động đọc lại dữ liệu mới nhất.

---

### 2. Ma trận mức độ hoàn thiện của các mô-đun

| Phân hệ / Mô-đun | Trạng thái kỹ thuật | Mức độ hoàn thiện logic | Nguồn dữ liệu thực tế | Nhận định kiến trúc |
| :--- | :--- | :--- | :--- | :--- |
| **Khởi động & Điều hướng gốc** (`AppBootstrap`, `SplashScreen`, `HomeScreen`) | Hoàn thiện (Production Ready) | 100% | Supabase Bootstrap, DI (`initDI`), SharedPreferences | Hoạt động trơn tru. Tự động chuyển thẳng vào Guest mode. 5 Tab chính duy trì bằng `IndexedStack`. |
| **Hành trình học chính (Core Journey)** (`LearningSectionsScreen`, `SectionUnitsScreen`, `UnitOverviewScreen`) | Hoàn thiện (Production Ready) | 95% | RPC `learning_sections_v2`, `learning_units_v2`, `unit_learning_path_v2` | Lộ trình trực quan, hỗ trợ mở khóa tuần tự, phân nhóm ải học theo kỹ năng. |
| **Ải thử thách Duo (Duo Game Runner)** (`DuoGameRunnerScreen`) | Hoàn thiện (Production Ready) | 95% | RPC `duo_level_challenges`, bảng `duo_active_sessions`, RPC `complete_learning_activity_v2` | Hỗ trợ 11 dạng thử thách (trắc nghiệm, ghép câu, chọn từ, nghe, nói, v.v.). Tự động lưu tiến trình dở dang. |
| **Phiêu lưu từ vựng (Vocabulary Adventure)** (`VocabularyAdventureScreen`) | Hoàn thiện (Production Ready) | 95% | Bảng `duo_levels`, `duo_units`, `lexicon_words`, RPC `record_word_progress` | 4 giai đoạn học lặp lại (Khám phá, Nhận diện, Nhớ lại, Ứng dụng). Hỗ trợ phát âm và lưu session. |
| **Boss Battle Hành trình** (`BossBattleScreen` từ `UnitOverview`) | Hoàn thiện | 90% | Bảng `lexicon_words`, RPC `start_boss_attempt`, `processBossReward` | Đấu Boss theo lượt, tính máu Dragon & Player, cộng XP thật từ RPC, mở khóa bài học kế tiếp. |
| **Boss Battle Game Hub** (`BossBattleGameplayScreen` từ `GameHubScreen`) | **MỚI CÓ UI - THIẾU LOGIC DỮ LIỆU** | **30%** | Mock / Random bộ từ, biến RAM `currentBossStageLevel` | **NGHIÊM TRỌNG**: Chiến thắng Boss KHÔNG gọi RPC, KHÔNG cộng XP, KHÔNG lưu lịch sử, cấp độ Boss nằm trên RAM (mất khi thoát app). |
| **4 Mini-game Game Hub** (Tone Ninja, Restaurant, Radical, Quick Answer) | Hoàn thiện logic | 90% | Bảng `lexicon_words`, `LearningRewardService.completeActivity` | Đầy đủ gameplay và thưởng XP thật (`game_mission`). Tuy nhiên mỗi game tự khởi tạo `FlutterTts` riêng. |
| **Luyện viết chữ Hán** (`HanziWritingHomeScreen`, `HanziWritingScreen`) | Hoàn thiện logic | 85% | Bảng `lexicon_characters`, `lexicon_hanzi_progress`, SVG canvas painter | Vẽ và chấm điểm từng nét theo thuật toán vector. Bị nghẽn hiệu năng do tải lại toàn bộ từ điển mỗi lần đổi chữ. |
| **Luyện phát âm (Speaking)** (`SpeakingScreen`) | Hoàn thiện logic | 80% | Bảng `lexicon_words` (`tts_url`), `speech_to_text` | Nhận diện giọng nói, so sánh độ tương đồng. **Điểm yếu**: Không có fallback sang TTS nếu `tts_url` trống. |
| **Ôn tập & Spaced Repetition (SRS)** (`ReviewScreen`, `FlashcardsScreen`, `QuizScreen`) | Hoàn thiện cho User, **Hỏng với Guest** | 60% | Bảng `lexicon_user_progress`, RPC `record_word_progress`, `mark_word_learned` | Với User đã login: Chạy đúng thuật toán SRS. **Với Guest: Bị bỏ qua hoàn toàn** do hàm DB trả về rỗng nếu `currentUser == null`. |
| **Ngữ pháp & Bài học** (`LessonsScreen`) | Hoàn thiện UI & Nội dung | 75% | Bảng `lexicon_units`, `lexicon_words`, Gemini Edge Function | Hiển thị từ vựng & hội thoại thật từ DB, làm giàu ngữ pháp bằng AI. Không có cơ chế lưu hoàn thành bài học. |
| **Giao tiếp AI (Conversations)** (`ConversationsScreen`) | Hoàn thiện | 90% | Supabase Edge Function `gemini-ai-gateway`, `history_logs.json` | Tạo hội thoại theo chủ đề và cấp HSK, lưu vào file lịch sử cục bộ, hỗ trợ phát âm TTS. |
| **Từ điển thông minh (Dictionary)** (`DictionaryScreen`) | Hoàn thiện | 90% | Supabase Edge Function `gemini-ai-gateway`, `speech_to_text`, `history_logs.json` | Tra cứu nghĩa, ví dụ, bộ thủ, phát âm, dịch câu bằng AI và giọng nói. |
| **Thi thử HSK (HSK Exam)** (`HskExamScreen`) | Hoàn thiện UI & Chấm điểm | 70% | Gemini AI Gateway, `history_logs.json` | Tạo đề thi, chấm điểm khách quan và phân tích điểm mạnh/yếu bằng AI. **Hạn chế**: Không cộng XP vào hệ thống học tập chung. |
| **Lịch sử & Thống kê** (`HistoryScreen`, `StatsScreen`, `XpHistoryScreen`) | Hoàn thiện | 85% | Bảng `learning_attempts`, `learning_xp_events`, file `history_logs.json` | Đã tách bạch rõ ràng giữa "Lịch sử học tập chính thức" và "Lịch sử công cụ AI". |
| **Hồ sơ & Thành tích** (`ProfilePage`) | Hoàn thiện UI | **50%** | Bảng `app_user_stats`, RPC `learning_stats` | **Lỗi đồng bộ Guest**: Với khách, gọi `DbHelper.getStats()` trả về toàn 0 mặc dù khách đã có XP và Streak trong SharedPreferences. |

---

### 3. Những vấn đề cốt lõi phát hiện được (Core Issues & Red Flags)

1. **Phân nhánh hai hệ thống Boss đối nghịch**:
   - Hệ thống Boss 1 (`BossBattleScreen`): Nằm trong lộ trình bài học (`UnitOverviewScreen`), có kết nối với `LearningRewardService`, gọi RPC Supabase, tính toán mở khóa ải và trao thưởng hợp lệ.
   - Hệ thống Boss 2 (`BossBattleGameplayScreen`): Nằm trong `GameHubScreen`. Khi chiến thắng chỉ gọi callback giao diện `onVictory()`, không gọi bất kỳ lệnh lưu trữ nào, không cộng XP (màn hình chiến thắng hiển thị 0 XP mặc định), biến cấp độ Boss lưu bằng `static int currentBossStageLevel` trong RAM và bị xóa sạch khi đóng app.
2. **Bộ điều khiển Boss bị bỏ rơi (Orphaned Controller)**:
   - File `BossBattleController` (361 dòng mã với State Machine hoàn chỉnh) hoàn toàn không được sử dụng bởi màn hình `BossBattleScreen` (màn hình này là một `StatefulWidget` khổng lồ 1181 dòng tự quản lý toàn bộ logic combat, animation và TTS).
3. **Mô-đun Ôn tập (SRS) và Hồ sơ (Profile) bị "mù" với tài khoản Khách (Guest)**:
   - Các phương thức trong `DbHelper` (`getReviewWords`, `upsertProgress`, `markLearned`, `getStats`) có câu lệnh ngắt `if (_client.auth.currentUser == null) return;`.
   - Hậu quả: Người dùng trải nghiệm ở chế độ Khách (vốn là chế độ mặc định hiện nay) không thể lưu tiến độ từ vựng ôn tập, tab Review luôn báo 0 từ cần ôn, và màn hình Profile luôn hiển thị 0 EXP / 0 Streak dù ở trang chủ Home vẫn hiển thị số XP tích lũy thực tế.
4. **Kiến trúc Text-To-Speech (TTS) bị phân mảnh và thiếu cơ chế phòng vệ**:
   - Đã tồn tại một `TtsService` tập trung được đăng ký trong `initDI()`, nhưng các màn hình (`BossBattleScreen`, `ToneNinjaScreen`, `BossBattleGameplayScreen`, `VocabularyAudioService`) lại tự khởi tạo các đối tượng `FlutterTts()` riêng lẻ.
   - Không có bước kiểm tra khả dụng của ngôn ngữ tiếng Trung (`isLanguageAvailable('zh-CN')`), dẫn đến việc nếu thiết bị Android chưa tải gói giọng nói Google TTS tiếng Trung, ứng dụng sẽ im lặng hoàn toàn mà không có thông báo cho người dùng.
5. **Nghẽn cổ chai tải dữ liệu tại mô-đun Luyện viết chữ Hán**:
   - Phương thức `nextCharacter()` trong `HanziWritingController` gọi `_database.getCharactersForWriting()`. Phương thức này tải toàn bộ bảng `lexicon_characters` và duyệt đệ quy tải toàn bộ danh mục từ vựng `lexicon_words` (1000 từ mỗi trang) chỉ để lấy thông tin của một chữ Hán tiếp theo.
6. **Rò rỉ ngăn xếp điều hướng (Navigation Stack Leak) sau khi hạ Boss**:
   - Sau khi hoàn thành bài học tại `UnitCompleteScreen`, nút "Bài tiếp theo" kích hoạt `Get.off(() => UnitOverviewScreen(Unit 2))`. Vì trước đó `UnitOverviewScreen(Unit 1)` vẫn nằm ở đáy stack, người dùng sẽ có 2 màn hình UnitOverview xếp chồng lên nhau; khi bấm Back ở bài 2, người dùng bị văng ngược về bài 1 thay vì về trang chủ Home.

---

### 4. Kết luận sơ bộ & Định hướng

Hệ thống mã nguồn của **Pandarin** có chất lượng thiết kế kiến trúc rất cao tại tầng lõi (Core Learning Pipeline v2, Idempotent XP Ledger, Event-Driven Invalidation, RLS Security Policies). Tuy nhiên, các đợt phát triển tính năng nhanh và việc chuyển hướng toàn bộ người dùng sang trải nghiệm Khách (Guest Mode) đã tạo ra một số điểm ngắt liên kết dữ liệu giữa các màn hình UI phụ trợ và cơ chế lưu trữ bền vững.

**Chi tiết phân tích từng phần, chứng cứ mã nguồn, sơ đồ kiến trúc và khuyến nghị khắc phục được trình bày đầy đủ trong 13 tài liệu tiếp theo của bộ hồ sơ này.**
