# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 03. CHI TIẾT TƯƠNG TÁC GIAO DIỆN VÀ LUỒNG XỬ LÝ (UI INTERACTION LOGIC)

> **Cấu trúc trình bày quy chuẩn**:  
> **Screen → Widget → Event → Controller → Service → Database → State Update → UI Result**

---

### 1. Màn hình Khởi động (`SplashScreen`)

- **Truy cập**: Điểm khởi đầu ứng dụng khi chạy qua `ChineseMasterApp`.
- **Dữ liệu hiển thị**: Logo ứng dụng, hoạt họa scale/fade chữ Pandarin, trạng thái tải (`SplashLoadStatus`).
- **Nguồn dữ liệu**: Kiểm tra kết nối cơ sở dữ liệu Supabase qua `DbHelper.instance.database`.
- **Luồng xử lý (Code Trace)**:
  - **Screen**: `SplashScreen` (`lib/features/splash/splash_screen.dart`, L9-L100)
  - **Widget**: `SplashLoadStatus` (L94) hiển thị khi xảy ra lỗi. Nút "Thử lại" (`onRetry`).
  - **Event**: `initState()` gọi `SplashController.start()`.
  - **Controller**: `SplashController` (`lib/features/splash/controller/splash_controller.dart`, L16-L36).
  - **Service**: `DbHelper.instance.database`, `AuthController.continueAsGuest()`.
  - **Database**: Thực hiện truy vấn kiểm tra `lexicon_hsk_levels.select('id').limit(1)`.
  - **State Update**: Cập nhật `error.value = null` hoặc thông báo lỗi nếu timeout/offline.
  - **UI Result**: Nếu thành công -> `Get.off(() => const HomeScreen())`. Nếu thất bại -> hiển thị nút thử lại và thông điệp lỗi.
  - **Tính bền vững**: Không lưu trạng thái riêng; phiên người dùng được set thành `Guest` trong `AuthController`.

---

### 2. Bảng điều khiển Trang chủ (`HomeScreen` - Tab 0: `HomeDashboard`)

- **Truy cập**: Người dùng vào sau màn hình Splash hoặc bấm icon Tab 0.
- **Dữ liệu hiển thị**:
  - Chuỗi ngày học (Streak), Số bài đã học (Lessons), Điểm kinh nghiệm hôm nay (Today XP).
  - Thẻ bài học kế tiếp đề xuất (`journey.value`).
  - Danh sách thao tác nhanh (Quick Actions): Ngữ pháp, Luyện nghe, Luyện nói, Thử thách, Ôn tập.
- **Nguồn dữ liệu**:
  - `HomeController.stats` (từ `DbHelper.getStats()`).
  - `HomeController.journey` (từ `CloudHomeJourneyRepository.getCurrentJourney()`).
  - `HomeController.todayXp` (từ `SupabaseLearningHistoryRepository.fetchTodayXp()`).
- **Chi tiết tương tác từng nút bấm**:

#### A. Nút "HỌC BÀI TIẾP THEO" / Banner Hành trình (`HomeDashboardHeroCard`)
- **Widget**: `_HomeHeroCard` / CTA Button (`home_dashboard_hero_card.dart`).
- **Event**: `onTap` -> gọi `HomeScreen._openCurrentJourney()` (`home_screen.dart`, L124-L183).
- **Controller/Service**: `HomeController`, `LearningRecommendationService`.
- **Database**: Đọc từ `current_learning_unit_v2` RPC.
- **UI Result**: Mở `UnitOverviewScreen` với Binding tương ứng của bài học (`UnitOverviewBinding`), hoặc mở `LearningSectionsScreen` nếu chưa xác định được bài.

#### B. Quick Action: "Ngữ pháp"
- **Event**: `onTap` -> `Get.to(() => const LessonsScreen())`.
- **UI Result**: Mở màn hình bài học ngữ pháp.

#### C. Quick Action: "Luyện nghe"
- **Event**: `onTap` -> `Get.to(() => const ConversationsScreen())`.
- **UI Result**: Mở màn hình hội thoại AI.

#### D. Quick Action: "Luyện nói"
- **Event**: `onTap` -> `Get.to(() => const SpeakingScreen(), arguments: const {'standalone': true})`.
- **UI Result**: Mở màn hình luyện nói tự do.

#### E. Quick Action: "Thử thách"
- **Event**: `onTap` -> `Get.to(() => const HskQuizScreen())`.
- **UI Result**: Mở màn hình trắc nghiệm HSK nhanh.

#### F. Quick Action: "Ôn tập"
- **Event**: `onTap` -> `Get.to(() => const ReviewScreen())`.
- **UI Result**: Mở trung tâm ôn tập Spaced Repetition.

#### G. Vuốt làm mới (Pull-to-refresh)
- **Event**: Kích hoạt `onRefresh` -> gọi `HomeController.refreshStats()`.
- **Logic**: Tăng `_refreshRequest`, gửi 7 truy vấn độc lập song song (`loadSlice`), bảo vệ chống race-condition.
- **UI Result**: Cập nhật chỉ số XP, Streak, và trạng thái bài học mới nhất.

---

### 3. Tổng quan Bài học & Cây tiến trình (`UnitOverviewScreen`)

- **Truy cập**: Từ Home CTA, `SectionUnitsScreen`, hoặc `UnitScreen`.
- **Dữ liệu hiển thị**:
  - Tiêu đề chương/bài học, mục tiêu giảng dạy (`teaching_objective`).
  - Tỷ lệ hoàn thành, số ải đã qua/tổng số ải.
  - Danh sách các node ải học: Từ vựng, Nghe, Ghép câu, Hội thoại, Viết chữ Hán, Cổng Boss.
- **Nguồn dữ liệu**:
  - `UnitOverviewController.loadUnitOverview()` (`unit_overview_controller.dart`, L76-L160).
  - Gọi `LearningJourneyRepository.getUnitJourney(unitId)` và `getUnitStages(unitId)`.
  - RPC Supabase: `unit_learning_path_v2(p_unit_id)`. Với khách, gọi `_overlayGuestPath` qua `GuestJourneyResolver`.
- **Chi tiết tương tác**:

#### A. Nhấn vào Ải học mở khóa (`_StageTrailEntry` / `_openStage`)
- **Vị trí code**: `unit_overview_screen.dart`, L640-L740.
- **Sự kiện & Điều hướng theo loại ải**:
  1. **Ải `vocabulary`**:
     - Mở `VocabularyAdventureScreen` với `VocabularyAdventureBinding(levelId, gameId, gameName)`.
     - Chờ kết quả quay về (`.then(_handleStageReturn)`).
  2. **Ải `listening` / `sentence` / `dialogue` / `quiz`**:
     - Mở `DuoGameRunnerScreen` truyền `gameId`, `gameCode`, `levelId`, `unitId`.
     - Chờ kết quả quay về (`.then(_handleStageReturn)`).
  3. **Ải `hanzi`**:
     - Mở `HanziWritingScreen` với `LearningSourceContext(mode: LearningMode.duoMission)`.
  4. **Ải `speaking`**:
     - Mở `SpeakingScreen` với `unitId` và `LearningSourceContext`.
  5. **Ải `boss` / Cổng Boss**:
     - Kiểm tra điều kiện mở cổng: Nếu chưa đủ điều kiện, hiển thị `showLockedMissionSheet`.
     - Nếu đã mở cổng: Hiển thị hộp thoại `_openBossGateModal` -> Người dùng bấm "KHIÊU CHIẾN" -> Mở `BossBattleScreen(stage: bossStage)`.

#### B. Nhấn vào Ải học đang bị khóa
- **Event**: Kích hoạt `showLockedMissionSheet` (`lib/core/widgets/locked_mission_sheet.dart`).
- **UI Result**: Trượt lên BottomSheet thông báo: "Ải bài học chưa mở. Hoàn thành ải trước để mở khóa", kèm nút dẫn thẳng tới ải tiên quyết cần làm.

#### C. Xử lý khi hoàn thành một ải và quay lại màn hình (`_handleStageReturn`)
- **Vị trí code**: `unit_overview_screen.dart`, L369-L430.
- **Logic**:
  - Gọi lại `controller.loadUnitOverview()`.
  - Nếu kết quả là `isFightBoss` -> Tự động kích hoạt mở thẳng trận đấu Boss (`_openBoss`).
  - Nếu bài học đã hoàn tất toàn bộ (`controller.isUnitCompleted`) -> Điều hướng sang `UnitCompleteScreen`.
  - Nếu Cổng Boss vừa thức tỉnh (`!wasBossReady && controller.isBossReady`) -> Hiển thị SnackBar chúc mừng và tự động bật modal khiêu chiến Boss.

---

### 4. Ải thử thách Duo Runner (`DuoGameRunnerScreen`)

- **Truy cập**: Từ `UnitOverviewScreen` khi bấm vào ải nghe/nói/ghép câu/trắc nghiệm.
- **Dữ liệu hiển thị**: Thanh tiến trình câu hỏi, số máu/tim (nếu có), điểm số, combo, thẻ câu hỏi động theo loại thử thách.
- **Nguồn dữ liệu**:
  - `DuoGameRunnerController.initSession()` (`duo_game_runner_controller.dart`, L73-L141).
  - Gọi `LearningSessionComposer.composeSession()` -> truy vấn bảng `challenges` hoặc RPC `duo_level_challenges`.
  - Khôi phục phiên dở dang từ `duo_active_sessions` (hoặc SharedPreferences nếu là khách).
- **Chi tiết tương tác từng lượt**:

#### A. Trả lời câu hỏi (`submitAnswer`)
- **Event**: Bấm chọn phương án / bấm nút "KIỂM TRA".
- **Logic**:
  - Cập nhật `isAnsweredCorrectly.value = isCorrect`.
  - Nếu đúng: `score += 10`, `correctCount++`, `currentCombo++`.
  - Nếu sai: `wrongCount++`, `currentCombo = 0`, thêm câu hỏi vào `incorrectChallenges` để làm lại ở cuối phiên.
  - Tự động lưu tiến trình dở dang (`_saveSession()`) vào bảng `duo_active_sessions`.
  - Hiển thị thanh phản hồi `DuoAnswerFeedback` (xanh nếu đúng, đỏ nếu sai kèm đáp án đúng).

#### B. Nút "TIẾP TỤC" (`nextChallenge`)
- **Event**: Người dùng bấm nút tiếp tục sau khi xem phản hồi.
- **Logic**:
  - Nếu chưa hết câu: Tăng `currentIndex++`, reset trạng thái lượt chơi.
  - Nếu đã hết câu chính nhưng có câu làm sai: Nạp lại danh sách `incorrectChallenges` để người dùng làm lại đến khi đạt 100%.
  - Nếu đã hoàn thành toàn bộ: Gọi `_finishSession()`.

#### C. Hoàn tất phiên làm bài (`_finishSession`)
- **Vị trí code**: `duo_game_runner_controller.dart`, L210-L263.
- **Luồng ghi dữ liệu**:
  - Gọi `LearningRewardService.processDuoGameReward(...)`.
  - **Người dùng đăng nhập**: Gửi payload tới RPC `complete_learning_activity_v2`. Máy chủ ghi `learning_attempts`, `learning_xp_events`, cập nhật `app_user_stats`, tính toán `nextNodeId`.
  - **Khách (Guest)**: Xóa session dở dang, gọi `GuestLearningProgressStore.recordStagePassed()`, lưu điểm và sao vào SharedPreferences, tự động giải mã `reward.nextNodeId` và gọi `DuoDbHelper.unlockLevel()`.
  - Kích hoạt thông báo vô hiệu hóa cache tập trung qua `LearningProgressSyncService`.
  - Cập nhật UI: `isCompleted.value = true`, hiển thị hộp thoại hoàn thành `DuoGameCompletionDialog`.
  - Bấm "TIẾP TỤC" trên Dialog -> Gọi `Get.back(result: LearningNavigationOutcome.completed(...))`.

---

### 5. Phiêu lưu Từ vựng (`VocabularyAdventureScreen`)

- **Truy cập**: Từ `UnitOverviewScreen` khi bấm vào ải `vocabulary`.
- **Dữ liệu hiển thị**:
  - Thẻ chữ Hán lớn, Pinyin, nghĩa tiếng Việt, nút phát âm loa, hình ảnh minh họa.
  - 4 giai đoạn tiến hóa từ vựng: **Encounter (Làm quen) → Test (Nhận diện) → Recall (Nhớ lại) → Use (Ứng dụng)**.
- **Nguồn dữ liệu**:
  - `VocabularyAdventureRepository.loadMission()` -> đọc `duo_levels`, `duo_units`, `lexicon_words`.
- **Chi tiết tương tác**:
  - **Nút loa phát âm (`speakCurrent`)**: Gọi `VocabularyAudioService.speak(word.chinese)`.
  - **Nút "ĐÃ HIỂU" (Discovery)**: Gọi `completeDiscovery()`, tăng điểm và chuyển bước kế tiếp.
  - **Chọn đáp án trắc nghiệm (`submitAnswer`)**: Chấm điểm đúng/sai, cộng combo bonus, ghi nhận kết quả từng từ qua `recordWordOutcome` -> gọi RPC `record_word_progress`.
  - **Hoàn thành chặng (`_finishMission`)**: Gọi `VocabularyAdventureRepository.completeMission` -> `LearningRewardService.processVocabularyReward` -> gọi RPC `complete_learning_activity_v2` (hoặc lưu local store nếu là khách).

---

### 6. Trận chiến Boss Hành trình (`BossBattleScreen`)

- **Truy cập**: Từ `UnitOverviewScreen` khi mở Cổng Boss bài học.
- **Dữ liệu hiển thị**:
  - Đấu trường Arena 2D: Gấu trúc (Player) đối đầu Rồng (Boss).
  - Thanh máu Boss (`bossHp / maxBossHp`), Thanh máu Người chơi (`playerHp / maxPlayerHp`), Chỉ số Combo.
  - Thẻ câu hỏi HSK tốc độ cao (chọn từ, nghĩa, phát âm).
- **Nguồn dữ liệu**:
  - Đọc câu hỏi từ `DbHelper.instance.getRandomSpeakingItems()` hoặc từ vựng của Unit.
- **Chi tiết tương tác combat**:
  - Khởi tạo: Gọi `_rewardService.startBossAttempt()`.
  - **Người chơi chọn đúng**:
    - Hoạt họa Panda bắn tên/tấn công.
    - Hiển thị số sát thương nhảy nổi (`FloatingDamage`) trên đầu Boss.
    - Trừ máu Boss. Nếu `bossHp <= 0` -> Thắng trận!
  - **Người chơi chọn sai**:
    - Hoạt họa Rồng phun lửa / vồ đánh.
    - Camera rung lắc (`cameraShakeOffset`), màn hình chớp đỏ.
    - Trừ máu người chơi. Nếu `playerHp <= 0` -> Thua trận!
  - **Xử lý Chiến thắng (`_onVictory`)**:
    - Gọi `_rewardService.processBossReward(...)` -> ghi nhận hạ gục Boss lên Supabase (hoặc `_guestStore.recordBossWon` nếu là khách).
    - Gọi `Get.off(() => BossBattleVictoryScreen(xpEarned, stars, ...))`.
    - Tại màn hình Victory bấm "Tiếp tục" -> `Get.off(() => UnitCompleteScreen(...))`.
    - Tại `UnitCompleteScreen` bấm "Bài tiếp theo" -> Mở bài học mới.

---

### 7. Trận chiến Boss Game Hub (`BossBattleGameplayScreen`)

- **Truy cập**: Từ Tab 2 (Game Hub) -> `BossBattleIntroScreen` -> Bấm "Bắt đầu".
- **Dữ liệu hiển thị**: Giao diện đấu trường tương tự `BossBattleScreen`.
- **HÀNH VI DỮ LIỆU ĐẶC BIỆT (XÁC MINH LỖI THỰC TẾ)**:
  - Khi `bossHp <= 0`: Chỉ gọi hàm callback `widget.onVictory()`.
  - **KHÔNG GỌI** `LearningRewardService`.
  - **KHÔNG GỌI** RPC Supabase.
  - **KHÔNG GỌI** `GuestLearningProgressStore`.
  - Cấp độ Boss kế tiếp chỉ được tăng trên RAM: `currentBossStageLevel = level + 1;` tại `GameHubScreen`.
  - Khi mở màn hình `BossBattleVictoryScreen`, không truyền tham số XP -> Màn hình hiển thị `+0 XP`, `0% đúng`, `0 điểm`.

---

### 8. Luyện phát âm (`SpeakingScreen`)

- **Truy cập**: Từ Home Quick Actions, Tab 1 Learning, hoặc ải `speaking` trong bài học.
- **Dữ liệu hiển thị**: Câu mẫu tiếng Trung, Pinyin, bản dịch nghĩa, nút phát âm mẫu, nút Micro thu âm dạng sóng xung mạch (`pulseAnimation`), thanh đo độ tương đồng.
- **Chi tiết tương tác**:
  - **Bấm nút loa nghe mẫu**:
    - Nếu `item.audioUrl` tồn tại: Gọi `audioService.playUrl(item.audioUrl)`.
    - **LỖI PHÁT HIỆN**: Nếu `item.audioUrl` rỗng/null, nút loa bị vô hiệu hóa (`null`), không hề chuyển sang đọc bằng `TtsService`.
  - **Bấm nút Micro thu âm**:
    - Yêu cầu cấp quyền Micro qua `PermissionHelper.requestSpeakingPermissions()`.
    - Dừng mọi âm thanh đang phát (`audioService.stop()`).
    - Mở bộ thu âm `SpeechService.listen()`.
    - Người dùng nói tiếng Trung -> Bộ nhận dạng giọng nói trả về chuỗi text `recognizedText`.
    - Thuật toán `SpeechService.evaluateSpeech()` tính điểm phát âm, độ chính xác thanh điệu (Tone score), và độ lưu loát (Fluency).
    - Gửi kết quả về `LearningRewardService.completeActivity(activityType: 'speaking')` -> Cập nhật chỉ số kỹ năng Speaking trong `unit_mastery_v2`.

---

### 9. Luyện viết chữ Hán (`HanziWritingScreen`)

- **Truy cập**: Từ Tab 1 hoặc từ ải `hanzi` trong bài học.
- **Dữ liệu hiển thị**: Ô lưới Mễ tự (Rice Grid), chữ Hán mờ làm mẫu, các nét đã viết đúng màu xanh ngọc, nét vẽ tay tự do của người dùng.
- **Chi tiết tương tác**:
  - Khởi tạo: Nạp dữ liệu nét từ `lexicon_characters.stroke_paths` (dạng SVG Path). Phân tích thành các nét chuẩn qua `SvgStrokeParser`.
  - **Người dùng vẽ nét trên màn hình (`onPanUpdate`)**:
    - Thu thập tọa độ ngón tay qua `StrokeSampler`.
    - Khi người dùng nhấc tay (`onPanEnd`): Gọi `StrokeValidator.validateStroke()`.
    - So sánh thứ tự nét (Stroke Order), hướng vẽ (Direction) và độ khớp hình học (Shape Similarity).
    - Nếu đúng nét: Cố định nét vẽ thành màu xanh, phát hiệu ứng, chuyển sang yêu cầu nét kế tiếp.
    - Nếu sai nét: Báo đỏ rung lắc, yêu cầu vẽ lại nét đó.
  - **Hoàn thành chữ**:
    - Tính điểm trung bình các vòng viết.
    - Gọi `HanziWritingController.saveProgress()` -> `LearningRewardService.processHanziReward()`.
    - Ghi nhận vào bảng `lexicon_hanzi_progress` và cập nhật chỉ số kỹ năng Hanzi vào `unit_mastery_v2`.

---

### 10. Thi thử HSK AI (`HskExamScreen`)

- **Truy cập**: Từ Tab 3 (Tiến trình) -> Thẻ "Thi thử HSK".
- **Dữ liệu hiển thị**: Bộ đề thi hoàn chỉnh (Phần Nghe, Phần Đọc hiểu, Ngữ pháp) theo cấp độ HSK 1-6 được tạo động bởi Gemini.
- **Chi tiết tương tác**:
  - **Bấm "Tạo đề thi mới"**: Gọi `GeminiService.fetchHskExam(level)`.
  - **Làm bài**: Người dùng chọn đáp án A, B, C, D cho từng câu.
  - **Nộp bài (`submitExam`)**:
    1. Tính điểm số khách quan dựa trên đáp án đúng của đề thi.
    2. Lưu ngay kết quả thô vào tệp lịch sử cục bộ `history_logs.json` để bảo toàn dữ liệu trước khi gọi AI.
    3. Gửi toàn bộ câu hỏi và câu trả lời của người dùng lên `GeminiService.fetchHskExamAnalysis()` để phân tích điểm mạnh, điểm yếu và gợi ý lộ trình ôn luyện.
  - **HẠN CHẾ DỮ LIỆU**: Bài thi thử HSK hoàn toàn độc lập với hệ thống XP học tập; làm bài thi xong không được cộng XP vào tài khoản và không ghi nhận attempt lên bảng `learning_attempts`.
