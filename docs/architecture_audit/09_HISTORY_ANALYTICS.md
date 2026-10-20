# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 09. HỆ THỐNG LỊCH SỬ VÀ PHÂN TÍCH TIẾN TRÌNH (HISTORY & ANALYTICS AUDIT)

> **Phạm vi kiểm toán**: Bảng điều khiển tiến trình (Progress Dashboard), Thống kê trọn đời (Stats), Sổ cái giao dịch XP (XP Ledger), Lịch sử làm bài (Attempts Timeline), và Lịch sử tương tác công cụ AI (AI History Logs).

---

### 1. Phân định Hai hệ thống Lịch sử Song song (Two History Systems)

Sau đợt tái cấu trúc PR 09, hệ thống đã phân tách minh bạch giữa hai nguồn dữ liệu lịch sử trên giao diện `HistoryScreen` (`lib/features/history/history_screen.dart`):

```
                                  [LỊCH SỬ NGƯỜI DÙNG]
                                            │
                 ┌──────────────────────────┴──────────────────────────┐
                 ▼                                                     ▼
    [TAB 0: LỊCH SỬ HỌC TẬP CHÍNH THỨC]               [TAB 1: LỊCH SỬ CÔNG CỤ AI]
  - Nguồn dữ liệu: Supabase PostgreSQL              - Nguồn dữ liệu: Tệp cục bộ history_logs.json
  - Bảng: learning_attempts & learning_xp_events    - Định dạng: Mảng JSON cục bộ
  - Bản chất: Sổ cái bất biến, Server-Authoritative - Bản chất: Nhật ký tiện ích, có thể xóa sạch
  - Nội dung: Ải học, Điểm số, Sao, XP nhận được    - Nội dung: Tra từ điển, Hội thoại AI, Thi HSK
  - Xóa dữ liệu: KHÔNG ĐƯỢC PHÉP (Bảo vệ điểm)      - Xóa dữ liệu: Có nút "Xóa lịch sử AI"
```

---

### 2. Bản đồ Nguồn dữ liệu Phân tích trên Tab Tiến trình (Tab 3: Progress Dashboard)

Mọi chỉ số hiển thị trên Tab 3 và `StatsScreen` đều được truy vết về nguồn dữ liệu thực tế:

| Chỉ số hiển thị | Nguồn dữ liệu Signed-in | Nguồn dữ liệu Guest | Tần suất làm mới & Cơ chế Cache |
| :--- | :--- | :--- | :--- |
| **XP Hôm nay (Today XP)** | Bảng `learning_xp_events` lọc theo `user_id` và `created_at >= startOfToday` | Khóa `guest_learning_xp_events_v2` trong SharedPreferences lọc theo ngày hôm nay | Tự động làm mới khi có sự kiện `LearningDomain.history` hoặc khi mở app |
| **Tổng XP Trọn đời (Lifetime XP)** | Bảng `app_user_stats.total_exp` | Tổng cộng trường `xp_amount` trong `guest_learning_xp_events_v2` | Đồng bộ theo thời gian thực |
| **Chuỗi ngày học (Current Streak)** | Bảng `app_user_stats.current_streak` | Khóa `guest_learning_stats_v2.current_streak` trong SharedPreferences | Cập nhật khi vượt qua ải học đầu tiên trong ngày |
| **Biểu đồ XP 7 ngày gần nhất (7-Day XP)** | Tính tổng theo ngày từ 200 bản ghi gần nhất của `learning_xp_events` | Tính tổng theo ngày từ mảng `guest_learning_xp_events_v2` | Khung 7 cột tương ứng 7 ngày (Thứ 2 đến Chủ nhật) |
| **Hồ sơ Thông thạo 4 Kỹ năng (Skill Mastery)** | RPC `unit_mastery_v2` hoặc trung bình có trọng số từ `learning_attempts` | `GuestLearningProgressStore` kết hợp `_fetchLocalUnitMastery` | 4 thanh đo phần trăm: Từ vựng (35%), Nghe (25%), Nói (20%), Viết (20%) |
| **Dòng thời gian Hoạt động gần đây (Timeline)** | 50 bản ghi mới nhất từ `learning_attempts` (fallback sang `learning_xp_events`) | Mảng `guest_learning_attempts_v2` trong SharedPreferences | Hiển thị loại hoạt động, tiêu đề ải, điểm số, số sao, thời gian tương đối |

---

### 3. Phân tích Dữ liệu Trang Hồ sơ & Thành tích (`ProfilePage`)

Màn hình `ProfilePage` (`lib/features/system/profile_page.dart`) hiển thị các huy hiệu thành tích và thông số tổng hợp. Quá trình kiểm toán phát hiện các vấn đề dữ liệu sau:

1. **Ngày học gần nhất bị giả lập (`lastStudyDate`)**:
   - Tại `_ProfilePageState._loadStats()` (dòng 55):
     ```dart
     return UserStats(
       id: 1,
       totalExp: exp,
       currentStreak: streak,
       lastStudyDate: DateTime.now(), // GIẢ LẬP THỜI ĐIỂM HIỆN TẠI!
       totalWordsMastered: mastered,
       totalFavorites: favorites,
     );
     ```
   - Giá trị `lastStudyDate` không được đọc từ cột `last_study_date` của bảng `app_user_stats`, mà luôn được gán bằng `DateTime.now()`.
2. **Khách vãng lai (Guest) luôn bị hiển thị 0 điểm trên Profile**:
   - `ProfilePage` gọi trực tiếp `DbHelper.instance.getStats()`.
   - Trong `DbHelper.dart` (dòng 293-307):
     ```dart
     final userId = _client.auth.currentUser?.id;
     if (userId == null) {
       return {
         'learned': 0, 'mastered': 0, 'correct': 0, 'wrong': 0,
         'speakingAttempts': 0, 'speakingAverage': 0,
         'streak': 0, 'totalExp': 0, 'favorites': 0, 'wordsMastered': 0,
       };
     }
     ```
   - **Hậu quả**: Khi khách vãng lai đã học xong nhiều bài, tích lũy hàng trăm XP hiển thị ở trang chủ Home, nhưng khi bấm vào `ProfilePage`, màn hình hiển thị toàn bộ chỉ số là 0 (0 EXP, 0 ngày chuỗi, 0 từ tinh thông).

---

### 4. Đứt gãy Liên kết giữa Hoạt động AI và Sổ cái Học tập

Các tính năng sử dụng trí tuệ nhân tạo Gemini (`ConversationsScreen`, `HskExamScreen`, `DictionaryScreen`):
- **Hoạt động rất tốt về mặt AI sinh nội dung** (phản hồi nhanh, tạo câu hỏi chuẩn cấp độ HSK, phân tích lỗi sai chi tiết).
- **Tuy nhiên, chúng tồn tại hoàn toàn biệt lập với Hệ sinh thái Gamification**:
  - Hoàn thành một bài thi HSK Exam dài với điểm số tuyệt đối 100/100 **không đem lại 1 điểm XP nào** trên thanh tiến trình.
  - Luyện nói hội thoại 10 câu với AI **không được tính vào chỉ số kỹ năng Speaking** của bài học hay hồ sơ cá nhân.
  - Tra cứu 50 từ trong từ điển **không được tính vào số từ vựng tiếp cận** trong ngày.
  - Mọi kết quả này chỉ được ghi vào tệp JSON `history_logs.json` mà không tạo ra bất kỳ bản ghi nào trong bảng `learning_attempts` hay `learning_xp_events`.
