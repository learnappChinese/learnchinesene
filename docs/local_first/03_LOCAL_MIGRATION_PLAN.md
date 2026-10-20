# PANDARIN LOCAL-FIRST ARCHITECTURE
## 03. KẾ HOẠCH & TRIỂN KHAI DI CHUYỂN DỮ LIỆU KHÁCH (GUEST DATA MIGRATION)

> **Mục tiêu**: Chuyển đổi toàn bộ tiến trình học tập, lịch sử lượt làm bài, chiến thắng Boss và sổ cái kinh nghiệm (XP) của Khách vãng lai từ `SharedPreferences` sang cơ sở dữ liệu `SQLite` (`pandarin.db`), đảm bảo tính nhất quán, giao dịch nguyên tử (atomic transaction) và không làm mất bất kỳ dữ liệu cũ nào.

---

### 1. Bảng Ánh xạ Dữ liệu (Source SharedPreferences → Destination SQLite)

| Key SharedPreferences cũ | Kiểu dữ liệu gốc | Bảng SQLite đích | Cột đích & Quy tắc chuyển đổi |
| :--- | :--- | :--- | :--- |
| `guest_learning_completed_stages_v1` | JSON Map `'$gameId:$levelId'` -> Object | `local_stage_progress` | `local_id`: UUID Profile<br>`level_id`: `levelId`<br>`status`: `'completed'`<br>`best_score`: MAX(`best_score`, `score`)<br>`best_stars`: MAX(`best_stars`, `stars`)<br>`first_completed_at_utc`: `completed_at` |
| `guest_learning_completed_bosses_v1` | JSON Map `'unit_id'` -> Object | `local_stage_progress` | `local_id`: UUID Profile<br>`level_id`: `'boss:' \|\| unit_id`<br>`status`: `'completed'`<br>`best_score`: `score`<br>`best_stars`: `stars` |
| `guest_learning_attempts_v2` | JSON List (Stringified attempts) | `local_activity_attempts` | `attempt_id`: `id`<br>`local_id`: UUID Profile<br>`activity_type`: `activity_type`<br>`source_namespace`: `source_type`<br>`source_id`: `source_id`<br>`status`: `status` (`'passed'`, `'failed'`, `'abandoned'`)<br>`score`, `accuracy`, `stars`, `duration_seconds`<br>`metadata_json`: `jsonEncode(metadata)` |
| `guest_learning_xp_events_v2` | JSON List (XP Event objects) | `local_xp_events` | `event_id`: UUID mới<br>`event_key`: `event_key` (UNIQUE)<br>`local_id`: UUID Profile<br>`base_xp`, `bonus_xp`, `xp_amount`<br>`earned_at_utc`: `created_at`<br>`reward_rule_version`: 1 |
| `guest_learning_stats_v2` | JSON Map (`total_exp`, `current_streak`, `last_study_date`) | `local_study_days` & `local_xp_events` | `local_study_days`: Lưu ngày `last_study_date` (`YYYY-MM-DD`).<br>Nếu `total_exp > sum(local_xp_events)`, tạo sự kiện bù đắp: `event_key: 'legacy_guest_initial_xp_migration'`. |
| Bản ghi hỏng hoặc lỗi định dạng | Bất kỳ dữ liệu JSON lỗi / hỏng | `unresolved_legacy_progress` | `id`: UUID<br>`source_key`: tên key<br>`source_record_json`: raw string<br>`unresolved_reason`: lý do chi tiết |

---

### 2. Các Nguyên tắc Bất biến (Core Invariants)

1. **Bảo tồn nguyên vẹn SharedPreferences (No Data Deletion)**:
   - Toàn bộ các key `guest_learning_*` và `guest_progress_*` trên `SharedPreferences` **giữ nguyên 100%**, không bị xóa hay ghi đè trong quá trình migration.
   - Cho phép quay lui (rollback) an toàn trong trường hợp khẩn cấp.

2. **Idempotency (Không nhân đôi dữ liệu & XP)**:
   - Dịch vụ ghi nhận trạng thái vào bảng `local_migration_log` (`source_key = 'shared_preferences_guest_v1'`).
   - Các lệnh ghi vào SQLite sử dụng `INSERT OR IGNORE` và `ON CONFLICT(...) DO UPDATE SET ...` với hàm `MAX()`.
   - Cột `event_key` trong `local_xp_events` có ràng buộc `UNIQUE`, ngăn chặn triệt để hành vi nhân đôi điểm kinh nghiệm khi migration chạy lại.

3. **Giao dịch Nguyên tử (Atomic Transaction)**:
   - Toàn bộ quá trình import được bọc trong `db.transaction((txn) async { ... })`.
   - Nếu xảy ra lỗi bất ngờ, toàn bộ transaction được rollback, database giữ nguyên trạng thái nhất quán.

4. **Sổ cái XP Thống nhất (Single Source of Truth for Stats)**:
   - Màn hình Home, Profile và Dashboard đều đọc `totalExp` và `streak` thông qua `AppDatabase.instance.getTotalXp()` và `AppDatabase.instance.getCurrentStreak()`.
   - Lỗi hiển thị 0 EXP trên màn hình cá nhân của Khách (Guest) đã được giải quyết triệt để.

---

### 3. Khắc phục Lỗi Rò rỉ Navigation Stack (Back Stack Leak)

- **Vấn đề cũ**: Trong `UnitCompleteScreen._onGoToNextUnit()`, ứng dụng sử dụng `Get.off(() => UnitOverviewScreen())`. Lệnh này chỉ thay thế màn hình hoàn thành trên cùng, trong khi các màn hình `UnitOverviewScreen` cũ và Game screens trước đó vẫn nằm nguyên trong ngăn xếp điều hướng, gây rò rỉ bộ nhớ và làm chuỗi Back bị lặp vô tận: `[Home, Unit 1, Boss, Unit 2, Boss, Unit 3...]`.
- **Giải pháp**:
  ```dart
  void _onGoToNextUnit() {
    if (_nextUnit != null) {
      final next = _nextUnit!;
      // Dọn dẹp toàn bộ màn hình trung gian về root tab trước khi mở Unit mới
      Get.until((route) => route.isFirst);
      Get.to(
        () => const UnitOverviewScreen(),
        binding: UnitOverviewBinding(
          unitId: next.id,
          unitTitle: next.title,
          sectionNumber: next.sectionNumber,
          unitNumber: next.unitNumber,
        ),
      );
    } else {
      Get.until((route) => route.isFirst);
    }
  }
  ```

---

### 4. Kết quả Kiểm thử Tự động (Automated Verification)

Toàn bộ 6/6 test cases trong `test/core/database/local_guest_migration_service_test.dart` và các test hồi quy liên quan đều đã vượt qua 100%:

1. `Migration converts guest stages, bosses, attempts and XP to SQLite`: **PASS**
2. `Idempotency: re-running migration does not duplicate data or XP`: **PASS**
3. `SharedPreferences keys are NOT wiped or deleted during migration`: **PASS**
4. `Fallback baseline XP is created if total_exp in stats exceeds ledger`: **PASS**
5. `Atomic Learning Completion persists to SQLite and handles double tap`: **PASS**
6. `GuestLearningProgressStore reads & writes SQLite cohesively`: **PASS**
7. `UnitCompleteScreen renders victory UI and next unit action`: **PASS**
8. `guest_learning_progression_test.dart` (12/12 tests): **PASS**
9. `learning_reward_service_test.dart` (19/19 tests): **PASS**
10. `learning_flow_unlock_boss_navigation_test.dart` (11/11 tests): **PASS**
11. `auth_guest_cloud_migration_test.dart` (12/12 tests): **PASS**
12. `home_dashboard_test.dart` (6/6 tests): **PASS**
13. `home_personal_tab_test.dart` (5/5 tests): **PASS**
14. `flutter analyze`: **0 Errors**
