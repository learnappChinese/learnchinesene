# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 07. HỆ THỐNG HỌC TIẾNG TRUNG VÀ PHÁT ÂM TTS (CHINESE LEARNING & TTS AUDIT)

> **Phạm vi kiểm toán**: Giáo trình HSK, Từ vựng, Chữ Hán, Ngữ pháp, Hội thoại, Luyện nói, Ôn tập Spaced Repetition (SRS) và toàn bộ hạ tầng âm thanh Text-To-Speech (TTS).

---

### 1. Phân hệ Từ vựng & Giáo trình HSK (Vocabulary & Curriculum)

Hệ thống giáo trình tiếng Trung trong Pandarin được cấu trúc thành 3 phân tầng nội dung:

```
[HSK Levels 1 - 6] (bảng lexicon_hsk_levels)
       │
       ▼
[Units / Bài học] (bảng lexicon_units & duo_units)
       │
       ├──► [Từ vựng trọng tâm] (bảng lexicon_words)
       │         ├── Chữ Hán giản thể (word)
       │         ├── Phiên âm thanh điệu (pinyin)
       │         ├── Nghĩa tiếng Việt (meaning_vi)
       │         └── Âm thanh bản xứ URL (tts_url)
       │
       ├──► [Câu ví dụ & Hội thoại] (bảng lexicon_examples)
       │         ├── Câu tiếng Trung (sentence_cn)
       │         ├── Phiên âm (sentence_pinyin)
       │         └── Bản dịch tiếng Việt (sentence_vi)
       │
       └──► [Chữ Hán & Nét viết] (bảng lexicon_characters)
                 ├── Số nét (stroke_count)
                 └── Tọa độ vector SVG (stroke_paths)
```

#### Quy trình 4 bước Phiêu lưu Từ vựng (`VocabularyAdventureScreen`)
Mỗi ải từ vựng trong lộ trình bài học không chỉ kiểm tra trắc nghiệm đơn thuần mà áp dụng chu trình thụ đắc ngôn ngữ 4 pha:
1. **Pha 1: Encounter (Làm quen)**: Hiển thị chữ Hán lớn, Pinyin, nghĩa tiếng Việt, phát âm tự động và hình ảnh trực quan. Người chơi bấm "ĐÃ HIỂU" để ghi nhận điểm tiếp cận.
2. **Pha 2: Test (Nhận diện)**: Trắc nghiệm 4 phương án chọn nghĩa tiếng Việt đúng cho chữ Hán đang học.
3. **Pha 3: Recall (Nhớ lại)**: Hiển thị nghĩa tiếng Việt, yêu cầu người chơi chọn chữ Hán và Pinyin tương ứng mà không có gợi ý.
4. **Pha 4: Use (Ứng dụng)**: Đưa từ vựng vào một câu ví dụ hoàn chỉnh, yêu cầu điền khuyết hoặc ghép nghĩa câu.

---

### 2. Phân hệ Luyện viết chữ Hán (`HanziWritingScreen`)

- **Công nghệ render**: Custom Painter trên Flutter Canvas kết hợp phân tích đường dẫn vector SVG (`path_drawing`).
- **Nguồn dữ liệu**: Cột `stroke_paths` trong bảng `lexicon_characters` lưu trữ chuỗi các thẻ SVG `<path d="..." />`.
- **Quy trình thẩm định nét viết (`StrokeValidator`)**:
  1. **Thứ tự nét (Stroke Order)**: Người học bắt buộc phải viết đúng thứ tự nét từ nét số 1 đến nét cuối cùng theo chuẩn bút thuận quốc tế. Viết sai thứ tự bị từ chối ngay lập tức.
  2. **Hướng di chuyển của bút (Direction)**: So sánh góc vector giữa điểm đầu và điểm cuối của nét vẽ tay với nét vector chuẩn (ví dụ: nét Ngang phải viết từ Trái sang Phải, nét Phẩy phải vẽ từ Phải trên xuống Trái dưới).
  3. **Độ tương đồng hình học (Geometric Distance)**: Thuật toán lấy mẫu `StrokeSampler` chia đều nét vẽ thành các điểm kiểm tra và tính toán khoảng cách sai lệch tối đa.
- **Vấn đề phát hiện**:
  - Tại `HanziWritingController.nextCharacter()` (`lib/features/hanzi_writing/controller/hanzi_writing_controller.dart`, L94-L100): Mỗi khi chuyển sang một chữ Hán mới, hàm này gọi `_database.getCharactersForWriting()`. Hàm này duyệt tải toàn bộ 1000 ký tự từ bảng `lexicon_characters` và duyệt đệ quy tải toàn bộ từ điển `lexicon_words` (1000 từ/trang). Đây là nguyên nhân gây giật lag (frame drop) rõ rệt trên thiết bị di động khi luyện viết nhiều chữ liên tục.

---

### 3. Phân hệ Luyện phát âm (Speaking & Speech Recognition)

- **Công nghệ**: `speech_to_text: ^7.4.0` kết hợp thuật toán so khớp ngữ âm.
- **Tiêu chuẩn chấm điểm (`SpeechService.evaluateSpeech`)**:
  - Độ chính xác phát âm (Pronunciation Score): Dựa trên khoảng cách Levenshtein giữa chuỗi ký tự nói và chuỗi mẫu.
  - Độ chính xác thanh điệu (Tone Score): Đánh giá việc phát âm đúng 4 thanh điệu chuẩn tiếng Quan Thoại.
  - Độ lưu loát (Fluency Score): Đo lường khoảng ngừng nghỉ và tốc độ phát âm.
- **Hạn chế kỹ thuật phát hiện**:
  - Tại `speaking_screen.dart` (L168-L170):
    ```dart
    SpeakingPromptCard(
      item: item,
      onPlayAudio: item.audioUrl == null || item.audioUrl!.isEmpty
          ? null // NÚT BỊ VÔ HIỆU HÓA HOÀN TOÀN!
          : () => controller.audioService.playUrl(item.audioUrl!),
    )
    ```
  - Nếu từ vựng hoặc câu ví dụ chưa có link file âm thanh `audioUrl` trong database, nút loa bị tắt hẳn (`null`). Hệ thống **hoàn toàn không có cơ chế dự phòng (fallback)** tự động gọi `TtsService.speak(item.targetText)` để đọc chữ Hán bằng giọng máy, khiến người học không nghe được mẫu để phát âm theo.

---

### 4. Phân hệ Ôn tập Spaced Repetition (SRS) & Quiz

Hệ thống có hai phân hệ trắc nghiệm song song:

1. **Trắc nghiệm Giáo trình (`HskQuizScreen` trong `features/hsk_quiz/`)**:
   - Sử dụng `CloudHskQuizRepository`.
   - Sinh câu hỏi tự động từ các từ vựng thật trong bảng `lexicon_words` thuộc cấp độ HSK được chọn.
   - Hoạt động độc lập, có thể luyện tập bất kỳ lúc nào mà không phụ thuộc vào trạng thái đăng nhập.
2. **Trắc nghiệm Ôn tập SRS (`QuizScreen` & `ReviewScreen` trong `features/quiz/` và `features/review/`)**:
   - Dựa trên thuật toán khoảng cách lặp lại (Spaced Repetition).
   - Truy vấn các từ trong bảng `lexicon_user_progress` có `mastered = false` và `next_review_at <= now()`.
   - Khi trả lời đúng, `next_review_at` được đẩy xa hơn trong tương lai (1 ngày -> 3 ngày -> 7 ngày -> 30 ngày); khi trả lời sai, từ bị đánh dấu `wrong_count++` và hạn ôn tập bị kéo về ngay lập tức.
   - **LỖI NGHIÊM TRỌNG ĐỐI VỚI GUEST**: Cả hai hàm `DbHelper.getReviewWords()` và `DbHelper.upsertProgress()` đều kiểm tra `if (_client.auth.currentUser == null) return;`. Do đó, người dùng Khách vãng lai hoàn toàn không sử dụng được tính năng SRS này; từ học xong không bao giờ được đưa vào danh sách cần ôn tập.

---

### 5. KIỂM TOÁN CHUYÊN SÂU HẠ TẦNG TEXT-TO-SPEECH (TTS DEEP-DIVE AUDIT)

#### A. Database lưu Text, Audio URL hay Dữ liệu âm thanh thực tế?
- **Kết luận**: Database **KHÔNG lưu dữ liệu âm thanh thực tế** (không lưu BLOB hay binary mp3).
- Các cột âm thanh trong database (`lexicon_words.tts_url`, `challenges.tts`, `challenges.tokens_tts`, `challenges.choices_tts`, `duo_flashcards.tts_url`) đều là **chuỗi ký tự TEXT chứa đường dẫn URL** trỏ tới file MP3 được lưu trữ trên CDN/Supabase Storage.
- **Rủi ro thực tế**: Không phải tất cả từ vựng và câu hỏi đều có URL âm thanh. Rất nhiều bản ghi có giá trị `NULL` hoặc chuỗi rỗng `""`.

#### B. Phân định giữa `AudioService` (Audio Player) và `TtsService` (Engine TTS)
Hệ thống tồn tại hai kênh âm thanh độc lập hoàn toàn:

```
[Yêu cầu phát âm thanh]
          │
          ├──► Có URL âm thanh sẵn? ──► Dùng AudioService (audioplayers: ^6.7.1)
          │                                  └── Stream file MP3 từ máy chủ
          │
          └──► Không có URL / Văn bản tự do ──► Dùng TtsService / FlutterTts (flutter_tts: ^4.1.0)
                                                    └── Tổng hợp giọng nói cục bộ (zh-CN)
```

#### C. Thời điểm khởi tạo TTS Engine & Rủi ro chưa kiểm tra Ngôn ngữ
- `TtsService` tập trung được khởi tạo lười (`lazyPut`) trong `initDI()`.
- Phương thức `_ensureConfigured()` (`lib/core/services/tts_service.dart`, L18-L27):
  ```dart
  Future<void> _ensureConfigured({String language = 'zh-CN', double speechRate = 0.5}) async {
    if (_isConfigured) return;
    try {
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(speechRate);
      _isConfigured = true;
    } catch (e) {
      debugPrint('TtsService configuration warning: $e');
    }
  }
  ```
- **LỖI PHÒNG VỆ**:
  1. `TtsService` **KHÔNG GỌI `_tts.isLanguageAvailable('zh-CN')`** trước khi phát âm.
  2. Rất nhiều thiết bị Android nội địa hoặc giá rẻ chưa cài sẵn gói dữ liệu giọng nói tiếng Trung Quốc (Google Speech Recognition & Synthesis - Mandarin Chinese).
  3. Khi không có giọng đọc, lệnh `setLanguage('zh-CN')` hoặc `speak()` sẽ ném lỗi ngầm hoặc im lặng hoàn toàn. Lỗi này chỉ được ghi nhận bằng một dòng `debugPrint` trong console mà **không hề hiển thị thông báo hay hướng dẫn người dùng cài đặt gói giọng nói**.

#### D. Phân mảnh đối tượng `FlutterTts` (Fragmented Instances)
Mặc dù đã có `TtsService` tập trung trong `lib/core/services/`, việc rà soát code phát hiện nhiều màn hình vẫn tự ý tạo các đối tượng `FlutterTts` độc lập:
1. `BossBattleScreen` (`boss_battle_screen.dart`, L96): `final FlutterTts _tts = FlutterTts();`
2. `BossBattleGameplayScreen` (`boss_battle_gameplay_screen.dart`, L100): `final FlutterTts _tts = FlutterTts();`
3. `ToneNinjaScreen` (`tone_ninja_screen.dart`, L25): `final FlutterTts _tts = FlutterTts();`
4. `VocabularyAudioService` (`vocabulary_audio_service.dart`, L12): `_tts = tts ?? FlutterTts();`

Hậu quả: Việc tồn tại nhiều instance TTS không chia sẻ trạng thái có thể gây xung đột kênh âm thanh (Audio Focus Conflict), giọng đọc bị đè lên nhau nếu người dùng thao tác chuyển màn hình nhanh khi giọng đọc cũ chưa dứt.

#### E. Đồng bộ trạng thái âm thanh khi chuyển câu hoặc thoát màn hình
- Tại `DuoMultipleChoiceWidget` (`duo_multiple_choice_widget.dart`, L30-L75):
  - Khi widget nhận câu hỏi mới (`didUpdateWidget`), nó gọi `_stopAudio()` rồi mới kích hoạt phát âm câu mới:
    ```dart
    if (oldWidget.challenge.id != widget.challenge.id) {
      selectedIndex = null;
      _stopAudio();
      WidgetsBinding.instance.addPostFrameCallback((_) { _playPromptAudio(); });
    }
    ```
  - Khi widget bị hủy (`dispose()`), nó gọi `_audioPlayer.dispose()`.
  - Tuy nhiên, trong hàm phát chuỗi âm thanh của các từ khóa (`validUrls`), vòng lặp chờ phát từng từ có đoạn mã:
    ```dart
    await _audioPlayer.onPlayerComplete.first.timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
    ```
  - Nếu kết nối mạng chập chờn khiến file âm thanh thứ nhất tải chậm quá 2 giây, timeout sẽ kích hoạt và lệnh phát âm từ thứ hai sẽ lập tức cắt ngang từ thứ nhất, tạo ra trải nghiệm âm thanh giật cục.
