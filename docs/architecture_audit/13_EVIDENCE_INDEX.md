# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 13. MỤC LỤC TRA CỨU BẰNG CHỨNG MÃ NGUỒN VÀ CƠ SỞ DỮ LIỆU (EVIDENCE & ARTIFACTS INDEX)

> **Mục tiêu**: Cung cấp mục lục tra cứu tham chiếu chéo (Cross-Reference Index) chính xác từng đường dẫn tệp mã nguồn, lớp đối tượng, hàm xử lý, bảng cơ sở dữ liệu và thủ tục lưu trữ (RPC) được kiểm tra thực tế trong suốt quá trình kiểm toán.

---

### 1. Mục lục Bằng chứng Kiến trúc & Khởi động Ứng dụng

| Thành phần | Đường dẫn tệp mã nguồn (File Path) | Lớp / Đối tượng (Class / Symbol) | Dòng code tham chiếu | Chức năng kiểm toán thực tế |
| :--- | :--- | :--- | :--- | :--- |
| **App Bootstrap** | [`lib/main.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/main.dart) | `main()`, `PandarinApp` | L15-L85 | Khởi tạo `WidgetsFlutterBinding`, Supabase Client, nạp `AppTheme`, chạy `GetMaterialApp`. |
| **DI Khởi đầu** | [`lib/core/init/app_initializer.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/init/app_initializer.dart) | `AppInitializer.init()` | L10-L60 | Đăng ký dịch vụ vĩnh viễn (`permanent: true`): SharedPreferences, Supabase, Auth, Audio, TTS. |
| **Cấu hình Môi trường** | [`lib/core/config/app_config.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/config/app_config.dart) | `AppConfig` | L1-L35 | Định nghĩa Supabase URL, Anon Key, API Timeouts, Cache Keys, Version code. |
| **Điều hướng Cột mốc** | [`lib/core/navigation/main_tab_view.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/navigation/main_tab_view.dart) | `MainTabView`, `MainTabController` | L20-L110 | Quản lý `IndexedStack` duy trì trạng thái 5 Tab chính của ứng dụng. |
| **Quản lý Auth** | [`lib/features/auth/auth_controller.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/auth/auth_controller.dart) | `AuthController` | L25-L160 | Lắng nghe `onAuthStateChange`, quản lý `Rx<User?> currentUser`, đăng nhập Guest/Email/Google. |
| **Khởi động Splash** | [`lib/features/splash/splash_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/splash/splash_screen.dart) | `SplashScreen`, `SplashController` | L1-L85 | Tự động gọi `continueAsGuest()` nếu chưa có session Supabase sẵn có. |

---

### 2. Mục lục Bằng chứng Hệ thống Học tập (Curriculum & Learning)

| Phân hệ | Đường dẫn tệp mã nguồn (File Path) | Lớp / Phương thức (Class & Method) | Dòng code tham chiếu | Hành vi logic đã xác minh |
| :--- | :--- | :--- | :--- | :--- |
| **Lộ trình HSK** | [`lib/features/learning/learning_journey_page.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/learning/learning_journey_page.dart) | `LearningJourneyPage` | L40-L180 | Render lộ trình dạng cây (Curriculum Path), chọn cấp độ HSK 1-6. |
| **Bộ điều khiển Lộ trình** | [`lib/features/learning/learning_journey_controller.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/learning/learning_journey_controller.dart) | `LearningJourneyController` | L30-L240 | Lắng nghe `LearningProgressSyncService`, nạp units & stages, mở khóa bài kế tiếp. |
| **Tổng quan Unit** | [`lib/features/learning/unit_overview_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/learning/unit_overview_screen.dart) | `UnitOverviewScreen` | L25-L190 | Hiển thị danh sách các Stage Node và Boss Node cuối bài; kiểm tra điều kiện mở khóa. |
| **Thực hiện Ải học** | [`lib/features/learning/stage_play_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/learning/stage_play_screen.dart) | `StagePlayScreen`, `StagePlayController` | L45-L380 | Vòng lặp câu hỏi Duo: Multiple Choice, Listening, Order, Match, trừ tim, tính combo XP. |
| **Hoàn thành Unit** | [`lib/features/learning/unit_complete_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/learning/unit_complete_screen.dart) | `UnitCompleteScreen._onGoToNextUnit()` | L135-L145 | Gọi `Get.off(() => UnitOverviewScreen(nextUnit))` gây rò rỉ ngăn xếp navigation. |
| **Luyện viết Chữ Hán** | [`lib/features/tools/hanzi_writing_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/tools/hanzi_writing_screen.dart) | `HanziWritingScreen`, `HanziWritingController` | L80-L320 | Nét vẽ CustomPainter, đánh giá thứ tự nét. Bị nghẽn nạp lại toàn bộ từ điển mỗi khi đổi chữ. |
| **Luyện phát âm AI** | [`lib/features/tools/speaking_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/tools/speaking_screen.dart) | `SpeakingScreen`, `SpeakingController` | L35-L260 | Ghi âm micro, so khớp Pinyin, chấm điểm tương đồng phát âm. Thiếu fallback sang TTS. |
| **Ôn tập Flashcards SRS** | [`lib/features/review/review_page.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/review/review_page.dart) | `ReviewPage`, `ReviewController` | L30-L210 | Hiển thị số từ đến hạn ôn tập; lật thẻ flashcard 3D; thuật toán SM-2 SRS. |

---

### 3. Mục lục Bằng chứng Hệ thống Game & Boss Battle

| Tính năng | Đường dẫn tệp mã nguồn (File Path) | Lớp / Phương thức (Class & Method) | Dòng code tham chiếu | Phát hiện kiểm toán then chốt |
| :--- | :--- | :--- | :--- | :--- |
| **Curriculum Boss UI** | [`lib/features/boss_battle/boss_battle_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/boss_battle/boss_battle_screen.dart) | `BossBattleScreen` (`StatefulWidget`) | L50-L1181 | Đấu Boss theo từng Unit, 1181 dòng monolithic, gọi `processBossReward()` mở khóa Unit. |
| **Curriculum Boss Controller** | [`lib/features/boss_battle/boss_battle_controller.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/boss_battle/boss_battle_controller.dart) | `BossBattleController` | L1-L361 | **MÃ NGUỒN MỒ CÔI**: Không được bất kỳ màn hình nào khởi tạo hoặc lắng nghe. |
| **Game Hub Trung tâm** | [`lib/features/dragon_panda/screens/game_hub_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/dragon_panda/screens/game_hub_screen.dart) | `GameHubScreen` | L30-L290 | Điểm truy cập Minigames; lưu `currentBossStageLevel = 1` trên biến RAM biến động. |
| **Game Hub Boss Gameplay** | [`lib/features/dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart) | `BossBattleGameplayScreen` | L40-L450 | **KHÔNG LƯU TIẾN ĐỘ**: Thắng Boss chỉ gọi `widget.onVictory()`, không gọi DB/RPC, 0 XP. |
| **Ninja Chém Tone** | [`lib/features/dragon_panda/screens/tone_ninja/tone_ninja_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/dragon_panda/screens/tone_ninja/tone_ninja_screen.dart) | `ToneNinjaScreen` | L50-L520 | Minigame chém thanh điệu (1-4); tự khởi tạo instance `FlutterTts` riêng rẽ. |
| **Nối Từ Hán Tự** | [`lib/features/dragon_panda/screens/word_match/word_match_screen.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/dragon_panda/screens/word_match/word_match_screen.dart) | `WordMatchScreen` | L30-L380 | Lưới ghép cặp từ Hán tự và nghĩa tiếng Việt; tính điểm combo; âm thanh hiệu ứng. |

---

### 4. Mục lục Bằng chứng Dịch vụ Đồng bộ, Dữ liệu & Âm thanh

| Dịch vụ | Đường dẫn tệp mã nguồn (File Path) | Lớp / Phương thức (Class & Method) | Dòng code tham chiếu | Chức năng nghiệp vụ đã xác minh |
| :--- | :--- | :--- | :--- | :--- |
| **Sổ cái & Phần thưởng** | [`lib/core/services/learning_reward_service.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/services/learning_reward_service.dart) | `LearningRewardService.processReward()`, `processBossReward()` | L40-L195 | Xử lý ghi nhận hoàn thành ải / hạ boss; rẽ nhánh RPC Supabase hoặc SharedPreferences. |
| **Vòng lặp Đồng bộ** | [`lib/core/services/learning_progress_sync_service.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/services/learning_progress_sync_service.dart) | `LearningProgressSyncService` | L15-L85 | Quản lý Stream & Event Invalidation (`bumpStageSync`, `bumpUnitSync`) để báo UI refresh. |
| **Truy vấn CSDL & Cục bộ** | [`lib/core/services/db_helper.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/services/db_helper.dart) | `DbHelper` | L30-L380 | Đọc `lexicon_words`, `lexicon_characters`; kiểm tra `currentUser == null` gây ngắt tính năng Guest SRS. |
| **Dịch vụ Âm thanh URL** | [`lib/core/services/audio_service.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/services/audio_service.dart) | `AudioService.playUrl()`, `playAsset()` | L20-L110 | Quản lý phát file mp3 hiệu ứng và URL âm thanh từ Cloud CDN thông qua `audioplayers`. |
| **Tổng hợp Giọng nói TTS** | [`lib/core/services/tts_service.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/services/tts_service.dart) | `TtsService.speak()`, `init()` | L15-L90 | Bọc thư viện `flutter_tts`, đặt ngôn ngữ `zh-CN`, thiếu `isLanguageAvailable` check. |
| **Gateway Trí tuệ Nhân tạo** | [`lib/core/services/gemini_ai_service.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/services/gemini_ai_service.dart) | `GeminiAiService.callGateway()` | L25-L130 | Gọi Supabase Edge Function `gemini-ai-gateway` để sinh đề thi HSK, hội thoại, tra nghĩa. |
| **Nhật ký AI Cục bộ** | [`lib/core/services/history_service.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/services/history_service.dart) | `HistoryService.saveHistory()` | L20-L85 | Ghi mảng JSON vào tệp `history_logs.json` trong bộ nhớ cục bộ ứng dụng. |

---

### 5. Mục lục Bằng chứng Cơ sở Dữ liệu Supabase Cloud (PostgreSQL 15)

| Bảng / Thủ tục / Đối tượng | Tên định danh (Database Identifier) | Kiểu / Cấu trúc | RLS Policy | Mục đích lưu trữ thực tế |
| :--- | :--- | :--- | :---: | :--- |
| **Bảng Giáo trình** | `duo_units` | Table (id, hsk_level, unit_order, title, description, required_stars) | Read Public | Danh sách bài học theo chuẩn HSK 1-6. |
| **Bảng Ải học** | `duo_stages` | Table (id, unit_id, stage_order, title, stage_type, reward_xp) | Read Public | Các trạm dừng chân trong lộ trình bài học. |
| **Bảng Câu hỏi** | `duo_challenges` | Table (id, stage_id, word_id, challenge_type, prompt, audio_url) | Read Public | Nội dung chi tiết các câu hỏi kiểm tra kiến thức. |
| **Bảng Lựa chọn** | `duo_options` | Table (id, challenge_id, content, translation, is_correct) | Read Public | Các phương án trả lời đúng/sai của từng câu hỏi. |
| **Bảng Từ điển** | `lexicon_words` | Table (id, simplified, traditional, pinyin, meaning_vi, tts_url) | Read Public | Kho từ vựng tiếng Trung kèm phiên âm, dịch nghĩa và URL âm thanh. |
| **Bảng Hán tự** | `lexicon_characters` | Table (id, character, pinyin, radical, stroke_count, stroke_data) | Read Public | Dữ liệu tọa độ nét vẽ phục vụ bài tập luyện viết Chữ Hán. |
| **Bảng Tiến độ Ải** | `duo_level_progress` | Table (id, user_id, stage_id, is_completed, stars, highest_score) | User Only | Tiến độ đã hoàn thành các ải của người dùng đã đăng nhập. |
| **Bảng Sổ cái XP** | `learning_xp_events` | Table (id, user_id, xp_amount, source_type, source_id, created_at) | User Only | Sổ cái bất biến ghi nhận từng lần cộng/trừ XP. |
| **Bảng Lịch sử Làm bài** | `learning_attempts` | Table (id, user_id, stage_id, challenge_id, is_correct, time_spent_ms) | User Only | Nhật ký chi tiết từng lần trả lời câu hỏi phục vụ phân tích. |
| **Bảng Thống kê Cá nhân** | `app_user_stats` | Table (user_id, total_xp, current_streak, longest_streak, words_learned) | User Only | Tổng hợp chỉ số hồ sơ cá nhân của người dùng đã đăng nhập. |
| **Bảng Trạng thái SRS** | `user_vocabulary_progress`| Table (id, user_id, word_id, srs_stage, ease_factor, interval_days) | User Only | Trạng thái ghi nhớ và chu kỳ lặp lại Spaced Repetition của từng từ. |
| **Thủ tục Hoàn tất Ải** | `duo_complete_stage_transaction_v2` | Stored Procedure (RPC) | Security Definer | Giao dịch nguyên tử: Ghi progress, cộng XP vào sổ cái, tính streak. |
| **Thủ tục Thưởng Boss** | `duo_record_boss_reward_v2` | Stored Procedure (RPC) | Security Definer | Giao dịch nguyên tử: Ghi nhận hạ Boss, thưởng 50 XP, mở khóa Unit kế tiếp. |
| **Edge Function AI** | `gemini-ai-gateway` | Supabase Deno Edge Function | JWT Verified | Cổng proxy trung gian bảo mật giao tiếp giữa Flutter app và Gemini API. |

---

### 6. Mục lục Tra cứu 10 Lỗi Logic Đã Xác minh (Defect Cross-Reference)

| Mã lỗi | Mức độ | Tệp nguồn & Bằng chứng thực tế | Tài liệu phân tích chuyên sâu |
| :---: | :---: | :--- | :--- |
| **ISSUE-01** | **Critical (P0)** | `lib/features/dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart#L410-L425`<br>`lib/features/dragon_panda/screens/game_hub_screen.dart#L180-L195` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-01-thắng-boss-game-hub-không-lưu-tiến-độ-không-thưởng-xp-và-cấp-độ-nằm-trên-ram) |
| **ISSUE-02** | **Critical (P0)** | `lib/core/services/db_helper.dart#L145-L160`<br>`lib/features/review/review_controller.dart#L75-L95` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-02-chế-độ-khách-guest-làm-tê-liệt-hoàn-toàn-tính-năng-ôn-tập-srs) |
| **ISSUE-03** | **High (P1)** | `lib/features/learning/unit_complete_screen.dart#L135-L145` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-03-rò-rỉ-ngăn-xếp-điều-hướng-stack-leak-sau-khi-hạ-boss) |
| **ISSUE-04** | **High (P1)** | `lib/features/profile/profile_page.dart#L60-L80`<br>`lib/core/services/db_helper.dart#L280-L310` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-04-màn-hình-hồ-sơ-profilepage-luôn-hiển-thị-0-điểm-với-khách) |
| **ISSUE-05** | **High (P1)** | `lib/features/tools/hanzi_writing_screen.dart#L280-L315` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-05-nghẽn-hiệu-năng-luyện-viết-chữ-hán-hanzi-writing) |
| **ISSUE-06** | **Medium (P2)** | `lib/features/tools/speaking_screen.dart#L210-L235` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-06-thiếu-fallback-sang-tts-trong-speaking-practice) |
| **ISSUE-07** | **Medium (P2)** | `lib/core/services/tts_service.dart#L30-L55`<br>`lib/features/boss_battle/boss_battle_screen.dart#L140-L160` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-07-phân-mảnh-fluttertts-và-thiếu-kiểm-tra-gói-giọng-zh-cn) |
| **ISSUE-08** | **Medium (P2)** | `lib/features/tools/hsk_exam_screen.dart#L190-L220`<br>`lib/core/services/history_service.dart#L30-L50` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-08-hoạt-động-ai-tách-rời-khỏi-sổ-cái-xp-chung) |
| **ISSUE-09** | **Medium (P2)** | `lib/features/boss_battle/boss_battle_controller.dart#L1-L361`<br>`lib/features/boss_battle/boss_battle_screen.dart#L50-L1181` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-09-bossbattlecontroller-bị-bỏ-rơi-bossbattlescreen-ôm-đồm-logic) |
| **ISSUE-10** | **Low (P3)** | `lib/features/learning/boss_stage_map_screen.dart`<br>`lib/features/learning/learning_overview_screen.dart`<br>`lib/features/learning/word_list_screen.dart` | Xem [10_LOGIC_ISSUES.md](file:///d:/Projects/Flutter_Project/learnchinesene/docs/architecture_audit/10_LOGIC_ISSUES.md#issue-10-mã-nguồn-mồ-côi-không-thể-tiếp-cận-dead-code) |
