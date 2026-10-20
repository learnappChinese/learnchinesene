# PANDARIN LOCAL-FIRST ARCHITECTURE — CONTENT MAPPING & CURRICULUM QUALITY

> **Phiên bản:** 1.0.0 (Stage 3 Complete)  
> **Trạng thái:** Verified & Production Ready  
> **Mục tiêu:** Khảo sát, chuẩn hóa và kiểm thử luồng học giáo trình HSK 1–4 hoàn toàn offline thông qua SQLite `pandarin.db`, xóa bỏ lỗi chặn hành trình học của người dùng và thiết lập ranh giới trung thực cho HSK 5–6.

---

## 1. Tổng quan phân bổ giáo trình HSK 1–4 trong SQLite

Toàn bộ dữ liệu giáo trình HSK 1–4 được trích xuất trực tiếp từ các bảng Supabase thực tế (`lexicon_hsk_levels`, `lexicon_units`, `lexicon_words`, `lexicon_word_sources`, `lexicon_characters`, `lexicon_examples`) và đóng gói vào `assets/data/hsk_curriculum_pack_v1.json`. Khi ứng dụng khởi động ở chế độ Local-First, `AppDatabase.ensureContentPackSeeded()` bảo đảm toàn bộ nội dung được nạp bền vững vào SQLite:

| Cấp độ HSK | Số bài học (Units) | Số từ vựng thực tế | Số Hán tự đơn | Trạng thái hiển thị & mở khóa |
| :--- | :--- | :--- | :--- | :--- |
| **HSK 1** | 10 bài | 150 từ | 120 chữ | Mở sẵn Bài 1; Mở tuần tự từ Bài 2 đến Bài 10 sau khi diệt Boss |
| **HSK 2** | 20 bài | 300 từ | 185 chữ | Khóa ban đầu; Mở khi hoàn thành Bài 10 HSK 1 |
| **HSK 3** | 40 bài | 600 từ | 280 chữ | Khóa ban đầu; Mở khi hoàn thành Bài 20 HSK 2 |
| **HSK 4** | 60 bài | 1,155 từ | 350 chữ | Khóa ban đầu; Mở khi hoàn thành Bài 40 HSK 3 |
| **Tổng cộng** | **130 bài** | **2,205 từ** | **935 chữ** | **100% Offline (Không phụ thuộc mạng hay cloud DB)** |

### Ranh giới trung thực đối với HSK 5 & HSK 6
- Trong `HskController`: Đăng ký rõ ràng 6 cấp độ HSK, trong đó HSK 5 & 6 có tiêu đề `'HSK 5 (Chưa mở)'` và `'HSK 6 (Chưa mở)'`.
- Trong `HskScreen`: Kiểm tra `isUnlockedLevel = level.order <= 4`. Khi người dùng bấm vào HSK 5 hoặc HSK 6, hệ thống **không** sinh bài học giả hay crash màn hình, mà hiển thị thông báo thân thiện:
  > *"Giáo trình HSK 5 & 6 đang được biên soạn. Bạn hãy hoàn thành HSK 1–4 trước nhé!"*

---

## 2. Giải quyết lỗi chặn truy cập Ải từ vựng (`UnitOverviewScreen`)

### Vấn đề gốc (Root Cause AS-IS)
Trong phiên bản cũ, khi người dùng bấm vào một bài học trong `UnitScreen`, `UnitController.fetchUnitOverview()` gọi `getUnitJourney(unitId)`. Phương thức này cố gắng truy vấn bảng cloud `duo_levels` và `duo_units`. Khi không có kết nối Supabase, nó trả về `null`, dẫn đến màn hình bật một dialog lỗi gây ức chế:
> *"Bài từ vựng này chưa được liên kết với một ải trong hành trình"*

### Giải pháp kỹ thuật (TO-BE Implementation)
1. **`LearningJourneyRepository._getLocalSections()`**:
   - Truy vấn `AppDatabase.instance.getHskLevels()` và đếm số unit từ `AppDatabase.instance.getUnitsByHskLevel()`.
   - Kết hợp với `GuestJourneyResolver` và `GuestLearningProgressStore` để tính toán phần trăm hoàn thành và trạng thái mở khóa cục bộ.
2. **`LearningJourneyRepository._getLocalRawUnits(sectionId)`**:
   - Trích xuất `hskLevelId` từ mã section (`section_hsk_1` -> 1).
   - Lấy danh sách unit thực tế từ SQLite bảng `lexicon_units`.
3. **`LearningJourneyRepository._getLocalUnitStages(unitId)`**:
   - Xây dựng **4 ải chuẩn hóa (Canonical Stages)** cho mỗi bài học:
     1. **Ải 1: Từ vựng (`learnWords`)**: Lấy danh sách từ thuộc unit từ SQLite `lexicon_words`, trạng thái ban đầu `available`.
     2. **Ải 2: Hán tự (`hanziWriting`)**: Lấy danh sách chữ Hán từ `lexicon_characters` liên kết với từ trong unit. Mở khóa khi hoàn thành Ải 1.
     3. **Ải 3: Luyện nói (`speaking`)**: Tạo bài luyện âm và phát âm các câu/từ vựng trong unit. Mở khóa khi hoàn thành Ải 2.
     4. **Ải 4: Boss Battle (`boss`)**: Trận đấu trùm tổng hợp kiến thức cả bài. Mở khóa khi hoàn thành cả 3 ải thành phần.
4. **`LearningJourneyRepository.getUnitJourney(unitId)`**:
   - Khi không có dữ liệu cloud, tự động xây dựng một `ChapterAdventure` offline từ dữ liệu SQLite và trạng thái của 4 ải. Xóa bỏ hoàn toàn dialog lỗi.

---

## 3. Chiến lược tổng hợp bài tập Offline (`LearningSessionComposer`)

Khi người dùng tham gia học một ải mà không có mạng, `LearningSessionComposer` tự động fallback sang cơ chế tổng hợp challenge cục bộ thông qua `_synthesizeLocalChallenges(unitId, gameCode)`:

| Mã game (`gameCode`) | Kiểu dữ liệu sinh ra (`item.type`) | Nguồn dữ liệu & Thuật toán |
| :--- | :--- | :--- |
| `learn_words` | `DuoFlashcard` (`flashcard`) | Lấy danh sách từ từ SQLite, tạo thẻ học từ gồm chữ Hán, Pinyin, nghĩa tiếng Việt, âm thanh TTS mẫu |
| `select_answer` / `listen_select` | `DuoChallenge` (`select` / `listenTap`) | Sinh câu hỏi trắc nghiệm nghĩa tiếng Việt hoặc chữ Hán, tự động xáo trộn 3 phương án gây nhiễu (distractors) lấy từ các từ khác cùng unit |
| `word_connect` / `match_pairs` | `DuoPairChallenge` (`pair`) | Tạo các cặp ghép đối ứng chữ Hán ↔ Pinyin / Tiếng Việt |
| `speaking` | `DuoChallenge` (`speaking`) | Tạo câu hỏi luyện phát âm từ vựng chuẩn xác theo từ điển địa phương |

Cơ chế này đảm bảo không bao giờ ném ra `ContentUnavailableException` khi học ngoại tuyến.

---

## 4. Cơ chế lưu trữ tiến độ và mở khóa tuần tự (Sequential Progression)

- **Nguyên tắc không đốt cháy giai đoạn**:
  - Bài 1 luôn mở sẵn cho người học mới.
  - Bài `N+1` chỉ mở khóa khi người học **đánh bại Boss của Bài `N`** (`isBossWon(unitId) == true`).
  - Trong cùng một bài, thứ tự bắt buộc: **Từ vựng -> Luyện viết Hán tự -> Luyện nói -> Boss Battle**.
- **Tính bền vững của dữ liệu**:
  - Kết quả học từ vựng được ghi nhận đồng thời vào bảng `local_word_srs` trong SQLite và `GuestLearningProgressStore`.
  - Chiến thắng Boss được ghi nhận vào `local_boss_victories` và cấp XP, cập nhật streak vào `local_user_stats`.
  - Toàn bộ trạng thái tồn tại nguyên vẹn sau khi thoát app hoặc khởi động lại thiết bị mà không cần Internet.

---

## 5. Bằng chứng kiểm thử tự động (Automated Verification)

Test suite tích hợp `test/core/learning/local_hsk_curriculum_mapping_test.dart` gồm 7 test case:

```
00:00 +0: (setUpAll)
00:00 +0: Slice 3 — Local HSK Curriculum Mapping & Offline Learning Flow 1. Database has bundled HSK 1-4 curriculum content
00:00 +1: Slice 3 — Local HSK Curriculum Mapping & Offline Learning Flow 2. getSections() returns HSK 1-4 sections offline with sequential unlock
00:00 +2: Slice 3 — Local HSK Curriculum Mapping & Offline Learning Flow 3. getUnits() returns units with Unit 1 unlocked and Unit 2 locked initially
00:00 +3: Slice 3 — Local HSK Curriculum Mapping & Offline Learning Flow 4. getUnitStages() returns 4 canonical stages (Vocab, Hanzi, Speaking, Boss)
00:00 +4: Slice 3 — Local HSK Curriculum Mapping & Offline Learning Flow 5. Sequential stage completion unlocks next stages and defeats Boss to unlock Unit 2
00:00 +5: Slice 3 — Local HSK Curriculum Mapping & Offline Learning Flow 6. LearningSessionComposer synthesizes offline challenges without ContentUnavailableException
00:00 +6: Slice 3 — Local HSK Curriculum Mapping & Offline Learning Flow 7. VocabularyAdventureRepository loads mission from local SQLite words offline
00:00 +7: (tearDownAll)
00:00 +7: All tests passed!
```

- **Regression Database Tests**: 16/16 test cases trong `test/core/database/` passed.
- **Progression Tests**: 12/12 test cases trong `test/core/learning/guest_learning_progression_test.dart` passed.
- **Static Analysis**: 0 compilation errors, 0 warnings.
