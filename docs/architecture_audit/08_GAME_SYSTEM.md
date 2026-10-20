# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 08. HỆ THỐNG TRÒ CHƠI VÀ TRẬN CHIẾN BOSS (GAME SYSTEM & BOSS MECHANICS)

> **Mô hình Gamification**: Tích hợp yếu tố Game nhập vai kiếm hiệp / huyền huyễn phương Đông (Chinese Fantasy) vào tiến trình học tập: Bản đồ thế giới, Cây ải bài học, Đấu trường Boss rồng, và các Mini-game kỹ năng.

---

### 1. Phân tích Hai hệ thống Boss đối lập (Dual Boss System Audit)

Kiểm toán mã nguồn phát hiện một sự phân nhánh kiến trúc nghiêm trọng: **Ứng dụng tồn tại hai hệ thống Boss riêng biệt nhưng có giao diện và tên gọi gần như tương đồng**, dẫn đến sự bất nhất sâu sắc về mặt dữ liệu:

```
                                  [HỆ THỐNG BOSS TRONG APP]
                                              │
                 ┌────────────────────────────┴────────────────────────────┐
                 ▼                                                         ▼
    [1. CURRICULUM BOSS BÀI HỌC]                                [2. GAME HUB DRAGON BOSS]
  - File: lib/features/boss_battle/                           - File: lib/features/dragon_panda/
          boss_battle_screen.dart                                     boss_battle_gameplay_screen.dart
  - Nguồn mở: UnitOverviewScreen (Cổng Boss)                  - Nguồn mở: Tab 2 Game Hub (Khiêu chiến Boss)
  - Controller: StatefulWidget nội bộ (1181 dòng)             - Controller: StatefulWidget nội bộ (1074 dòng)
  - Kết nối dữ liệu: CÓ                                       - Kết nối dữ liệu: KHÔNG (NGẮT KẾT NỐI)
  - Ghi nhận: complete_learning_activity_v2 / local store     - Ghi nhận: Chỉ gọi widget.onVictory() UI
  - Phần thưởng: XP thật (20-100 XP), Sao, Lịch sử            - Phần thưởng: 0 XP (Mặc định), Không sao
  - Trạng thái: Lưu bền vững (Mở bài học kế tiếp)             - Trạng thái: Lưu RAM (static int level = 1)
```

#### Bảng so sánh chi tiết giữa hai hệ thống Boss

| Tiêu chí kỹ thuật | Boss Hành trình (`BossBattleScreen`) | Boss Game Hub (`BossBattleGameplayScreen`) | Đánh giá kiến trúc |
| :--- | :--- | :--- | :--- |
| **Màn hình kích hoạt** | `UnitOverviewScreen` qua `_openBoss` / `_openBossGateModal` | `GameHubScreen` qua `_openBossGameplay` | Hai điểm vào hoàn toàn độc lập |
| **Công thức Máu Boss (`bossHp`)** | `maxBossHp = 250 + (stageLevel * 60)` | `maxBossHp = 250 + (stageLevel * 60)` | Công thức giống nhau |
| **Công thức Máu Player (`playerHp`)** | `maxPlayerHp = 200` | `maxPlayerHp = 200` | Công thức giống nhau |
| **Sát thương gây cho Boss** | `combo * 15 + 25` | `combo * 15 + 25` | Công thức giống nhau |
| **Sát thương Boss đánh Player** | `30 - (combo * 2)` (tối thiểu 15) | `30 - (combo * 2)` (tối thiểu 15) | Công thức giống nhau |
| **Gọi API / Service khi kết thúc** | **CÓ**: Gọi `_rewardService.processBossReward(...)` | **KHÔNG**: Chỉ gọi `widget.onVictory()` | **LỖI LOGIC NẶNG ở Game Hub** |
| **Lưu vào Cơ sở dữ liệu** | **CÓ**: Ghi bản ghi `boss` vào `learning_attempts`, ghi `learning_xp_events` | **KHÔNG**: Không chạm vào bất kỳ bảng DB nào | Mất dữ liệu trên Game Hub |
| **Mở khóa nội dung tiếp theo** | **CÓ**: Đánh dấu hoàn thành bài học, mở khóa Unit tiếp theo | **KHÔNG**: Chỉ tăng biến RAM `currentBossStageLevel++` | Thoát app bị reset về Cấp 1 |
| **Hiển thị màn hình Chiến thắng** | Truyền `reward.xpEarned`, `reward.stars` vào `BossBattleVictoryScreen` | Không truyền tham số -> Victory Screen hiển thị `+0 XP` | Gây thất vọng cho người chơi |

---

### 2. Chi tiết Cơ chế Game và Công thức Tính thưởng

#### A. Điều kiện Bắt đầu & Mở cổng Boss (Boss Gate Unlocking)
- Người chơi không thể đánh Boss ngay từ đầu bài học.
- Điều kiện mở Cổng Boss:
  - **Signed-in**: Căn cứ vào cờ `boss_ready` trả về từ RPC `unit_learning_path_v2` (yêu cầu hoàn thành tối thiểu 80% các ải học hoặc vượt qua tất cả các ải tiên quyết).
  - **Guest**: Căn cứ vào `GuestJourneyResolver.isBossReady()`. Yêu cầu toàn bộ các ải có `node_type == 'learning'` trong Unit đó phải được đánh dấu hoàn thành trong `GuestLearningProgressStore`.

#### B. Công thức Thưởng XP Chuẩn (`LearningRulesService.evaluate`)
Khi người chơi vượt qua một ải học hoặc trận đấu Boss, điểm kinh nghiệm được tính toán theo công thức server-authoritative:

$$\text{Tổng XP} = \text{Base XP} + \text{First Clear Bonus} + \text{Perfect Bonus} + \text{Combo Bonus}$$

1. **Base XP**:
   - Ải học thông thường (Vocabulary, Listening, Reading): 10 XP.
   - Luyện phát âm (Speaking): 15 XP.
   - Luyện viết chữ Hán (Hanzi): 15 XP.
   - Trận chiến Boss: 50 XP (kèm thêm XP theo độ khó bài học).
2. **First Clear Bonus (Thưởng vượt ải lần đầu)**:
   - Nếu `first_clear == true`: Cộng thêm 50% Base XP (ví dụ: Boss được cộng thêm 25 XP).
   - Nếu chơi lại ải đã hoàn thành: `first_clear == false`, không cộng thêm bonus này.
3. **Perfect Bonus (Đúng 100% không sai câu nào)**:
   - Cộng thêm +5 XP nếu `accuracy == 1.0`.
4. **Combo Bonus**:
   - Combo >= 10: +4 XP.
   - Combo >= 5: +2 XP.

#### C. Chống cộng trùng XP khi Chơi lại nhiều lần (Replay Idempotency)
- Trong bảng `learning_xp_events`, trường `event_key` có ràng buộc `UNIQUE (user_id, event_key)`.
- Định dạng event key: `${userId}_${sourceType}_${sourceId}_${attemptId}`.
- Nếu người chơi cố tình gửi hai request giống hệt nhau hoặc spam nút bấm, máy chủ Postgres sẽ bắt lỗi vi phạm Unique Constraint và trả về kết quả đã lưu trước đó kèm cờ `idempotent = true`, không bao giờ cộng điểm 2 lần.

---

### 3. Khảo sát 4 Mini-Game trong Game Hub

Khác với trận chiến Boss Game Hub, 4 trò chơi kỹ năng trong `features/dragon_panda/screens/` đã được đấu nối phần thưởng hợp lệ thông qua `LearningRewardService`:

#### 1. Ninja Trọng Âm (`ToneNinjaScreen`)
- **Cơ chế**: Người chơi chém các quả bóng mang thanh điệu (Thanh 1, 2, 3, 4, Thanh nhẹ) tương ứng với phát âm của chữ Hán bay lên màn hình.
- **Dữ liệu**: Lấy ngẫu nhiên từ `DbHelper.instance.getRandomSpeakingItems(limit: 20)`.
- **Ghi nhận thưởng** (L228): Gọi `LearningRewardService().completeActivity(activityType: 'game_mission', sourceId: 'mini_game:tone_ninja')`.
- **Hạn chế**: Mỗi lần chơi tự khởi tạo một đối tượng `FlutterTts` cục bộ.

#### 2. Nhà Hàng Trung Hoa (`ChineseRestaurantScreen`)
- **Cơ chế**: Khách hàng gọi món bằng tiếng Trung (Sủi cảo, Mì, Cơm, Trà). Người chơi phải bấm chọn đúng đĩa thức ăn tương ứng trước khi hết giờ.
- **Ghi nhận thưởng** (L348): Gọi `LearningRewardService().completeActivity(activityType: 'game_mission', sourceId: 'mini_game:chinese_restaurant')`.

#### 3. Ghép Bộ Thủ (`RadicalBuilderScreen`)
- **Cơ chế**: Cho trước một chữ Hán hoàn chỉnh (ví dụ: '休') và 4 bộ thủ thành phần (Bộ Nhân đứng '亻', Bộ Mộc '木', v.v.). Người chơi chọn đúng các bộ thủ cấu tạo nên chữ đó.
- **Ghi nhận thưởng** (L258): Gọi `LearningRewardService().completeActivity(activityType: 'game_mission', sourceId: 'mini_game:radical_builder')`.

#### 4. Đố Vui Thần Tốc (`QuickAnswerScreen`)
- **Cơ chế**: Trả lời nhanh trắc nghiệm nghĩa từ vựng tiếng Trung trong vòng 10 giây mỗi câu.
- **Ghi nhận thưởng** (L278): Gọi `LearningRewardService().completeActivity(activityType: 'game_mission', sourceId: 'mini_game:quick_answer')`.

---

### 4. Xử lý Thoát giữa chừng, Mất mạng và Bỏ cuộc (Abandonment Lifecycle)

- Trong toàn bộ các bộ điều khiển ải học (`DuoGameRunnerController`, `VocabularyAdventureController`, `SpeakingController`, `QuizController`):
  - Phương thức `onClose()` luôn kiểm tra:
    ```dart
    @override
    void onClose() {
      if (_attemptStarted && !isCompleted.value) {
        unawaited(
          _rewardService.abandonAttempt(
            _attemptId,
            metadata: const <String, dynamic>{'reason': 'runner_closed'},
          ),
        );
      }
      super.onClose();
    }
    ```
  - Khi người chơi bấm nút Back, vuốt thoát ứng dụng hoặc chuyển tab đột ngột, lời gọi `abandonAttempt` được phát đi ngầm (`unawaited`).
  - Phía máy chủ Supabase, hàm `abandon_learning_attempt_v2` cập nhật trạng thái bản ghi trong `learning_attempts` thành `'abandoned'`, ghi nhận thời gian kết thúc và lý do, đảm bảo số liệu thống kê tỷ lệ hoàn thành (Completion Rate) luôn phản ánh trung thực.
