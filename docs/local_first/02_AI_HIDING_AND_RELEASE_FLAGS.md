# Báo Cáo Ẩn Tính Năng AI & Feature Flags (Giai Đoạn 1)

> **Mục tiêu:** Ẩn toàn bộ tính năng AI (Gemini Conversation, AI Lessons, AI Exam, AI Dictionary) khỏi phiên bản ra mắt Local-First mà **không xóa mã nguồn**, chuyển các nút hành động cốt lõi về các tính năng Offline (Luyện viết chữ Hán, Flashcards).

---

## 1. Cơ Chế Điều Khiển Tính Năng: `FeatureFlags`

Được đặt tại [`lib/core/config/feature_flags.dart`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/core/config/feature_flags.dart):

```dart
abstract final class FeatureFlags {
  /// Bật/tắt các tính năng AI Generative (Gemini AI Conversation, AI Exam, AI Dictionary).
  /// Mặc định: FALSE trong phiên bản Local-First phát hành chính thức.
  static bool enableAi = false;

  /// Bật/tắt Game Hub (Minigames).
  static const bool enableGameHub = false;

  /// Bật/tắt chế độ đồng bộ Cloud.
  static const bool enableCloudSync = false;
}
```

---

## 2. Bản Đồ Ẩn & Điều Hướng Thay Thế

| Vị Trí UI | Thành Phần Ban Đầu (AI) | Trạng Thái Sau Khi Ẩn | Điều Hướng / Thay Thế Mới |
| :--- | :--- | :--- | :--- |
| **Home Dashboard** (Mục *Học nhanh*) | "Ngữ pháp" → `LessonsScreen` (Soạn bài AI) | **Đổi tên & đổi tuyến** | "Luyện viết" → [`HanziWritingHomeScreen`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/hanzi_writing/screens/hanzi_writing_home_screen.dart) (Offline) |
| **Home Dashboard** (Mục *Học nhanh*) | "Luyện nghe" → `ConversationsScreen` (Hội thoại AI) | **Đổi tên & đổi tuyến** | "Flashcards" → [`FlashcardsScreen`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/flashcards/flashcards_screen.dart) (SRS Offline) |
| **Tab Học tập** (`HomeLearningTab`) | Thẻ `Bài học chuyên đề AI` | **Ẩn hoàn toàn** qua `if (FeatureFlags.enableAi)` | Không hiển thị thẻ |
| **Tab Học tập** (`HomeLearningTab`) | Thẻ `Hội thoại tình huống AI` | **Ẩn hoàn toàn** qua `if (FeatureFlags.enableAi)` | Không hiển thị thẻ |
| **Tab Tiến độ** (`HomeProgressTab`) | `Thi Thử HSK Với Giáo Viên AI` | **Ẩn hoàn toàn** qua `if (FeatureFlags.enableAi)` | Không hiển thị thẻ |
| **Tab Tiến độ** (`HomeProgressTab`) | `Lịch Sử Dịch & Hội Thoại` (AI Utility) | **Ẩn hoàn toàn** qua `if (FeatureFlags.enableAi)` | Chỉ giữ `Sổ Lịch Sử Kinh Nghiệm (XP)` & `Chi Tiết Thống Kê Học Tập` |
| **Tab Cá nhân** (`HomePersonalTab`) | `Từ điển Việt ↔ Trung` (AI Dictionary) | **Ẩn hoàn toàn** qua `if (FeatureFlags.enableAi)` | Chỉ giữ `Hồ sơ người dùng` |
| **Chi tiết chương** (`LearningOverviewScreen`) | `_DialogueCard` ("Hội thoại theo ngữ cảnh") | **Ẩn hoàn toàn** qua `if (FeatureFlags.enableAi)` | Giữ các thẻ: Từ vựng, Trắc nghiệm, Luyện viết Hanzi |
| **Bộ điều khiển Ôn tập** (`ReviewController`) | Hết từ nghe ôn tập fallback sang `ConversationsScreen` | **Chuyển hướng Offline** | Mở [`FlashcardsScreen`](file:///d:/Projects/Flutter_Project/learnchinesene/lib/features/flashcards/flashcards_screen.dart) |
| **Lịch sử hoạt động** (`HistoryScreen`) | Tab & thống kê `Công cụ AI` | **Ẩn hoàn toàn** qua `if (FeatureFlags.enableAi)` | Chỉ hiển thị dòng thời gian học tập chính thức (`learningItems`) |
| **Dòng thời gian sự kiện** (`LearningHistoryRepository`) | Nhãn `Luyện phát âm AI` | **Đổi nhãn chuẩn hóa** | `Luyện phát âm` (tránh hiểu lầm dùng AI tạo sinh) |

---

## 3. Bảo Toàn Mã Nguồn AI

Mã nguồn liên quan đến AI được bảo tồn nguyên vẹn 100% trong repository:
- `lib/core/services/gemini_service.dart` (Client gọi Supabase Edge Function `gemini-ai-gateway`)
- `lib/core/ai/model/ai_gateway_exception.dart` (Xử lý lỗi AI Gateway)
- `lib/features/conversations/` (Toàn bộ controller, model, view Hội thoại tình huống)
- `lib/features/lessons/` (Toàn bộ controller, model, view Bài học chuyên đề)
- `lib/features/hsk_exam/` (Toàn bộ controller, model, view Thi thử HSK)
- `lib/features/dictionary/` (Toàn bộ controller, model, view Tra từ điển AI)

Khi muốn kích hoạt lại, chỉ cần đổi `FeatureFlags.enableAi = true;`.

---

## 4. Kết Quả Kiểm Thử Thực Tế

- `flutter analyze`: **0 lỗi** (Tất cả import và kiểu dữ liệu chuẩn xác).
- `flutter test test/core/database/`: **10/10 tests PASSED** (Bao gồm boot offline, nạp seed pack HSK 1–4, ghi chép XP, DbHelper).
- `flutter test test/screen/home/tab_header_alignment_test.dart`: **4/4 tests PASSED** (Xác nhận các thẻ hiển thị cân đối trên cả 4 kích thước màn hình).
- `flutter test test/screen/game_hub/game_hub_view_test.dart`: **4/4 tests PASSED**.
- `flutter test test/screen/ui_followup/remaining_screens_test.dart`: **14/14 tests PASSED**.
