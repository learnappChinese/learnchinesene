# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 10. MA TRẬN LỖI LOGIC VÀ RỦI RO HỆ THỐNG (LOGIC ISSUES & RISK MATRIX)

> **Nguyên tắc phân loại**:  
> - **Critical (P0)**: Phá vỡ tiến trình học tập, gây mất dữ liệu người dùng hoặc tê liệt luồng chính.  
> - **High (P1)**: Sai lệch dữ liệu giữa các màn hình, rò rỉ ngăn xếp điều hướng hoặc nghẽn hiệu năng nghiêm trọng.  
> - **Medium (P2)**: Thiếu cơ chế phòng vệ lỗi, phân mảnh kiến trúc hoặc tính năng phụ chưa đấu nối hoàn thiện.  
> - **Low (P3)**: Mã nguồn mồ côi (Dead/Orphaned code), nợ kỹ thuật không ảnh hưởng trực tiếp tới người dùng.

---

### Bảng Tổng hợp Ma trận Lỗi

| Mã lỗi | Mức độ | Phân hệ bị ảnh hưởng | Tên lỗi kỹ thuật | Mức độ chắc chắn |
| :---: | :---: | :--- | :--- | :---: |
| **ISSUE-01** | **Critical (P0)** | Game Hub / Boss Battle | Thắng Boss Game Hub không lưu trữ, không thưởng XP, cấp độ nằm trên RAM | **Confirmed** |
| **ISSUE-02** | **Critical (P0)** | Review / Flashcards / SRS | Chế độ Khách (Guest) làm tê liệt hoàn toàn tính năng Ôn tập Spaced Repetition | **Confirmed** |
| **ISSUE-03** | **High (P1)** | Navigation / Unit Overview | Rò rỉ ngăn xếp điều hướng (Stack Leak) khi chuyển sang bài tiếp theo sau khi hạ Boss | **Confirmed** |
| **ISSUE-04** | **High (P1)** | Profile / System | Màn hình Hồ sơ cá nhân (`ProfilePage`) luôn hiển thị 0 điểm và 0 Streak với Khách | **Confirmed** |
| **ISSUE-05** | **High (P1)** | Hanzi Writing / Performance | Nghẽn hiệu năng nghiêm trọng: Tải lại toàn bộ từ điển mỗi lần đổi chữ Hán | **Confirmed** |
| **ISSUE-06** | **Medium (P2)** | Speaking Practice | Không có cơ chế fallback sang TTS khi từ vựng thiếu URL âm thanh bản ngữ | **Confirmed** |
| **ISSUE-07** | **Medium (P2)** | Audio / TTS Subsystem | Phân mảnh đối tượng `FlutterTts` và thiếu kiểm tra ngôn ngữ tiếng Trung khả dụng | **Confirmed** |
| **ISSUE-08** | **Medium (P2)** | HSK Exam / Conversations | Hoạt động AI hoàn toàn tách rời khỏi hệ thống XP và thống kê học tập | **Confirmed** |
| **ISSUE-09** | **Medium (P2)** | Architecture / Boss | `BossBattleController` bị bỏ rơi; `BossBattleScreen` tự ôm đồm toàn bộ logic | **Confirmed** |
| **ISSUE-10** | **Low (P3)** | Legacy Cleanup | Mã nguồn mồ côi không thể tiếp cận (`BossStageMapScreen`, `LearningOverviewScreen`, `WordListScreen`) | **Confirmed** |

---

### Chi tiết Từng Lỗi và Bằng chứng Mã nguồn

---

#### ISSUE-01: Thắng Boss Game Hub không lưu trữ, không thưởng XP, cấp độ nằm trên RAM
- **Mức độ nghiêm trọng**: **Critical (P0)**
- **Phân hệ**: `lib/features/dragon_panda/screens/boss_battle/` & `lib/features/game_hub/`
- **Bằng chứng mã nguồn**:
  1. `lib/features/dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart`, L85-L95:
     ```dart
     if (bossHp <= 0) {
       widget.onVictory(); // CHỈ GỌI CALLBACK GIAO DIỆN, KHÔNG GỌI DỊCH VỤ THƯỞNG!
     }
     ```
  2. `lib/features/game_hub/game_hub_screen.dart`, L43 & L82-L91:
     ```dart
     static int currentBossStageLevel = 1; // BIẾN RAM STATIC - MẤT SẠCH KHI THOÁT APP!
     
     void _openVictory(int level) {
       Get.off(() => BossBattleVictoryScreen(
         onContinue: () {
           currentBossStageLevel = level + 1;
           _openBossGameplay(currentBossStageLevel);
         },
         onBackToHub: _back,
         // KHÔNG TRUYỀN xpEarned, score, accuracy -> MẶC ĐỊNH HIỂN THỊ 0 XP!
       ));
     }
     ```
- **Các bước tái hiện**:
  1. Từ trang chủ, bấm Tab 2 (Trò chơi).
  2. Bấm vào thẻ "Boss Battle Đại Chiến" -> Bấm "Bắt đầu".
  3. Đánh bại Boss Rồng.
  4. Màn hình chiến thắng hiện ra với thông số: `+0 XP`, `0% đúng`, `0 điểm`.
  5. Đóng ứng dụng hoàn toàn và mở lại -> Cấp độ Boss bị reset về Cấp 1; không có điểm XP nào được cộng vào tài khoản, không có bản ghi nào trong lịch sử làm bài.
- **Nguyên nhân gốc rễ**: Lập trình viên xây dựng giao diện Game Hub Boss độc lập với hệ thống giáo trình, chỉ tạo khung UI/Gameplay mà quên đấu nối vào `LearningRewardService`.
- **Hướng khắc phục**:
  - Tích hợp `LearningRewardService().completeActivity(activityType: 'boss', sourceId: 'hub_boss_$level')` khi Boss bị hạ.
  - Lưu cấp độ Boss đã vượt qua vào `SharedPreferences` (với khách) hoặc bảng tiến độ máy chủ (với signed-in).
  - Truyền dữ liệu XP và điểm số thực nhận vào `BossBattleVictoryScreen`.

---

#### ISSUE-02: Chế độ Khách (Guest) làm tê liệt tính năng Ôn tập Spaced Repetition (SRS)
- **Mức độ nghiêm trọng**: **Critical (P0)**
- **Phân hệ**: `lib/core/database/db_helper.dart` & `lib/features/review/`
- **Bằng chứng mã nguồn**:
  1. `lib/core/database/db_helper.dart`, L243-L245:
     ```dart
     Future<List<Word>> getReviewWords() async {
       final userId = _client.auth.currentUser?.id;
       if (userId == null) return <Word>[]; // LUÔN TRẢ VỀ RỖNG ĐỐI VỚI KHÁCH!
     ```
  2. `lib/core/database/db_helper.dart`, L273 & L285:
     ```dart
     Future<void> upsertProgress({required int wordId, required bool isCorrect, int level = 1}) async {
       if (_client.auth.currentUser == null) return; // BỎ QUA KHÔNG LƯU GÌ NẾU LÀ KHÁCH!
     }
     Future<void> markLearned(int wordId) async {
       if (_client.auth.currentUser == null) return; // BỎ QUA KHÔNG LƯU!
     }
     ```
- **Các bước tái hiện**:
  1. Mở ứng dụng (mặc định vào dưới tài khoản Khách).
  2. Vào Tab 1 -> Bấm "Thẻ Flashcards".
  3. Lật thẻ và bấm chọn các mức đánh giá "Khó", "Tốt", "Dễ".
  4. Quay lại trang chủ hoặc vào Tab "Ôn tập SRS".
  5. Mục "Cần ôn hôm nay" luôn luôn hiển thị 0 từ, danh sách từ đến hạn luôn rỗng.
- **Nguyên nhân gốc rễ**: `DbHelper` được thiết kế chỉ tương tác trực tiếp với bảng `lexicon_user_progress` trên Supabase khi có `userId`. Khi dự án chuyển sang mô hình Guest-First, phần lưu trữ tiến độ từ vựng cục bộ chưa được bổ sung vào `GuestLearningProgressStore`.
- **Hướng khắc phục**: Bổ sung bảng tiến độ từ vựng cục bộ trong `GuestLearningProgressStore` (`guest_lexicon_progress_v1`), cho phép lưu `word_id`, `wrong_count`, `next_review_at` vào SharedPreferences khi `_client.auth.currentUser == null`.

---

#### ISSUE-03: Rò rỉ ngăn xếp điều hướng (Stack Leak) khi sang bài tiếp theo sau khi hạ Boss
- **Mức độ nghiêm trọng**: **High (P1)**
- **Phân hệ**: `lib/features/unit_overview/page/unit_complete_screen.dart`
- **Bằng chứng mã nguồn**:
  - `unit_complete_screen.dart`, L73-L85:
    ```dart
    void _onGoToNextUnit() {
      if (_nextUnit != null) {
        Get.off(
          () => const UnitOverviewScreen(),
          binding: UnitOverviewBinding(
            unitId: _nextUnit!.id,
            unitTitle: _nextUnit!.title,
            sectionNumber: _nextUnit!.sectionNumber,
            unitNumber: _nextUnit!.unitNumber,
          ),
        );
      }
    }
    ```
- **Các bước tái hiện**:
  1. Vào bài học số 1 (`UnitOverviewScreen` Unit 1).
  2. Vượt qua các ải và đánh thắng Boss.
  3. Màn hình `UnitCompleteScreen` hiện ra -> Bấm nút "BÀI TIẾP THEO".
  4. Màn hình bài học số 2 (`UnitOverviewScreen` Unit 2) hiển thị.
  5. Bấm nút Back trên thanh AppBar của bài 2.
  6. Thay vì quay về trang chủ Home, người dùng bị văng ngược lại `UnitOverviewScreen` của Bài 1.
- **Nguyên nhân gốc rễ**: Trước khi vào Boss, `UnitOverviewScreen(Unit 1)` đã được đẩy vào stack bằng `Get.to()`. Sau khi hạ Boss, các màn hình trung gian dùng `Get.off()`, nhưng màn hình Unit 1 ban đầu vẫn nằm dưới đáy stack. Khi gọi `Get.off()` để mở Unit 2, Unit 2 chỉ thay thế `UnitCompleteScreen` chứ không thay thế Unit 1.
- **Hướng khắc phục**: Thay `Get.off()` bằng `Get.offUntil(() => const UnitOverviewScreen(), (route) => route.isFirst)` hoặc sử dụng `Get.offNamedUntil` để dọn sạch stack trước khi mở bài học mới.

---

#### ISSUE-04: Màn hình Hồ sơ cá nhân (`ProfilePage`) luôn hiển thị 0 điểm với Khách
- **Mức độ nghiêm trọng**: **High (P1)**
- **Phân hệ**: `lib/features/system/profile_page.dart`
- **Bằng chứng mã nguồn**:
  - `profile_page.dart`, L45: Gọi `final dbStats = await DbHelper.instance.getStats();`
  - `db_helper.dart`, L294-L306:
    ```dart
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {'totalExp': 0, 'streak': 0, 'mastered': 0, ...};
    }
    ```
- **Các bước tái hiện**:
  1. Dùng ứng dụng dưới chế độ Khách, hoàn thành 3 ải học (kiếm được 40 XP, chuỗi 1 ngày hiển thị đúng ở trang chủ).
  2. Bấm vào Tab 4 (Cá nhân) -> Bấm "Hồ sơ cá nhân & Thành tích".
  3. Màn hình Profile hiển thị: `0 EXP`, `0 Ngày chuỗi`, `0 Từ vựng`.
- **Nguyên nhân gốc rễ**: `ProfilePage` không đọc dữ liệu qua `LearningHistoryRepository` (nơi đã có sẵn logic fallback đọc SharedPreferences của khách), mà lại gọi trực tiếp `DbHelper.getStats()`.
- **Hướng khắc phục**: Sửa `ProfilePage` đọc thông số từ `LearningHistoryRepository.fetchLifetimeXp()`, `fetchStreak()` và `GuestLearningProgressStore`.

---

#### ISSUE-05: Nghẽn hiệu năng nghiêm trọng khi đổi chữ Hán luyện viết
- **Mức độ nghiêm trọng**: **High (P1)**
- **Phân hệ**: `lib/features/hanzi_writing/controller/hanzi_writing_controller.dart`
- **Bằng chứng mã nguồn**:
  - `hanzi_writing_controller.dart`, L94-L97:
    ```dart
    Future<({int? id, bool hasCharacters})> nextCharacter(int currentId) async {
      final characters = await _database.getCharactersForWriting();
    ```
  - `db_helper.dart`, L480 & L620-L640:
    ```dart
    final characters = await _client.from('lexicon_characters').select(...).range(0, 999);
    final words = await _fetchWordCatalog(); // VÒNG LẶP WHILE TẢI HẾT CẢ KHO TỪ VỰNG!
    ```
- **Các bước tái hiện**:
  1. Vào tính năng Luyện viết chữ Hán (`HanziWritingScreen`).
  2. Viết xong một chữ hoặc bấm nút "Chữ tiếp theo".
  3. Ứng dụng bị đơ (khựng giao diện 1-2 giây) do mạng phải tải hàng ngàn bản ghi từ Supabase để join dữ liệu trong RAM.
- **Nguyên nhân gốc rễ**: Hàm `nextCharacter` không truy vấn ID chữ tiếp theo qua phân trang hoặc SQL query đơn giản (`where id > currentId order by id limit 1`), mà lại tải toàn bộ danh mục chữ và từ vựng về máy khách để duyệt tìm vị trí index.
- **Hướng khắc phục**: Bổ sung hàm RPC hoặc câu lệnh truy vấn gọn: `select('id').gt('id', currentId).order('id').limit(1)`.

---

#### ISSUE-06: Không có cơ chế fallback sang TTS khi thiếu audioUrl trong Luyện phát âm
- **Mức độ nghiêm trọng**: **Medium (P2)**
- **Phân hệ**: `lib/features/speaking/speaking_screen.dart`
- **Bằng chứng mã nguồn**:
  - `speaking_screen.dart`, L168-L170:
    ```dart
    SpeakingPromptCard(
      item: item,
      onPlayAudio: item.audioUrl == null || item.audioUrl!.isEmpty
          ? null
          : () => controller.audioService.playUrl(item.audioUrl!),
    )
    ```
- **Các bước tái hiện**:
  1. Vào bài luyện nói của một từ vựng chưa được cập nhật file MP3 trên máy chủ (`tts_url` là null hoặc rỗng).
  2. Nút bấm hình loa phát âm bị mờ xám (vô hiệu hóa).
  3. Người dùng không thể nghe cách phát âm mẫu để lặp lại theo.
- **Hướng khắc phục**: Thay đổi điều kiện: Nếu `item.audioUrl` có sẵn -> dùng `audioService.playUrl()`; nếu không -> gọi `Get.find<TtsService>().speak(item.targetText)`.

---

#### ISSUE-07: Phân mảnh đối tượng `FlutterTts` và thiếu kiểm tra ngôn ngữ
- **Mức độ nghiêm trọng**: **Medium (P2)**
- **Phân hệ**: `lib/core/services/tts_service.dart` và các màn chơi mini-game
- **Bằng chứng mã nguồn**:
  - `tts_service.dart`, L20-L24: Gọi trực tiếp `setLanguage('zh-CN')` mà không gọi `_tts.isLanguageAvailable('zh-CN')`.
  - Các file tự tạo instance riêng: `boss_battle_screen.dart` (L96), `boss_battle_gameplay_screen.dart` (L100), `tone_ninja_screen.dart` (L25), `vocabulary_audio_service.dart` (L12).
- **Hậu quả**: Thiết bị không có gói tiếng Trung sẽ im lặng hoàn toàn; nguy cơ đè giọng khi người chơi thao tác nhanh giữa các màn hình.
- **Hướng khắc phục**: Buộc toàn bộ ứng dụng sử dụng duy nhất thực thể `TtsService` từ DI; bổ sung hàm kiểm tra `isLanguageAvailable` và hiển thị cảnh báo hướng dẫn cài đặt Google TTS tiếng Trung nếu thiếu.

---

#### ISSUE-08: Hoạt động AI hoàn toàn tách rời khỏi hệ thống XP và Thống kê học tập
- **Mức độ nghiêm trọng**: **Medium (P2)**
- **Phân hệ**: `lib/features/hsk_exam/` & `lib/features/conversations/`
- **Bằng chứng mã nguồn**:
  - `hsk_exam_controller.dart`, L115-L135: Sau khi tính điểm thi thử HSK, chỉ lưu vào `_history.saveHistory()` (file JSON cục bộ `history_logs.json`).
  - Không gọi `LearningRewardService.completeActivity()`, không ghi nhận attempt, không cộng XP.
- **Hướng khắc phục**: Đấu nối `submitExam()` với `LearningRewardService` để cấp điểm kinh nghiệm xứng đáng (ví dụ: +30 đến +50 XP khi hoàn thành bài thi thử HSK).

---

#### ISSUE-09: `BossBattleController` bị bỏ rơi; `BossBattleScreen` tự ôm đồm logic
- **Mức độ nghiêm trọng**: **Medium (P2)**
- **Phân hệ**: `lib/features/boss_battle/`
- **Bằng chứng mã nguồn**:
  - File `boss_battle_controller.dart` định nghĩa đầy đủ GetxController với State Machine, nhưng không được import hay sử dụng trong `boss_battle_screen.dart`.
  - `BossBattleScreen` tự duy trì 1181 dòng mã trong `StatefulWidget`.
- **Hậu quả**: Khó viết unit test tự động cho giao diện combat, trùng lặp code và gây nhầm lẫn khi bảo trì hệ thống.

---

#### ISSUE-10: Mã nguồn mồ côi không thể tiếp cận (Dead Code Cleanup)
- **Mức độ nghiêm trọng**: **Low (P3)**
- **Danh sách file**:
  - `lib/features/boss_battle/boss_stage_map_screen.dart` (610 dòng mã không có route nào trỏ tới).
  - `lib/features/learning_overview/learning_overview_screen.dart` (Giao diện cũ bị thay thế bởi `UnitOverviewScreen`).
  - `lib/features/word_list/word_list_screen.dart` (Chỉ được mở từ màn hình cũ).
- **Hậu quả**: Tăng dung lượng bundle app không cần thiết và gây nhiễu cho lập trình viên khi đọc hiểu dự án.
