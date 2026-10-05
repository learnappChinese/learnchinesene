# Rà soát UI architecture

Phạm vi: 38 file màn hình trong `lib/screen`, gồm các view chi tiết/tổng kết bên trong những file này. Đã refactor cả 38 file màn hình. Các thư mục đang tồn tại được sử dụng theo trạng thái hiện tại của workspace.

Các widget mới nhận dữ liệu immutable và callback, không tìm controller hoặc gọi repository. Màn hình giữ điều hướng, controller scope và các tài nguyên giao diện. `BottomActionBar`, `GameScreenHeader` và các widget Boss Battle sẵn có được tái sử dụng. Future số liệu HSK/unit được cache trong controller, có constructor injection và guard kết quả cũ/dispose. Các luồng tra từ, tải/rating flashcard, làm HSK Quiz, tìm chữ/lưu tiến độ luyện viết và tải cửa ải được chuyển sang controller. Controller thuộc từng widget được đăng ký một lần bằng tag riêng và xóa khi dispose; các tài nguyên animation, nhập liệu và debounce vẫn do State sở hữu.

## Phạm vi theo màn hình

| File | Kết quả |
| --- | --- |
| [boss_battle/boss_battle_screen.dart](../lib/screen/boss_battle/boss_battle_screen.dart) | Dùng lại top bar, HUD và question panel; giải phóng image/codec thuộc màn hình. |
| [boss_battle/boss_stage_map_screen.dart](../lib/screen/boss_battle/boss_stage_map_screen.dart) | Controller giữ Future tải cửa ải cho tới khi retry; item nhận stage và callback, giữ bố cục hiện tại. |
| [conversations/conversations_screen.dart](../lib/screen/conversations/conversations_screen.dart) | Tách ConversationBubble; văn bản và hành động phát âm là input. |
| [dictionary/dictionary_screen.dart](../lib/screen/dictionary/dictionary_screen.dart) | Tách DictionaryEntryView; controller tra từ/lưu lịch sử có dependency injection, bỏ kết quả cũ và không cập nhật sau dispose. |
| [dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart](../lib/screen/dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart) | Tách BossDefeatContent nhận callback; viewport cuộn giữ căn giữa và cho phép truy cập nút khi màn hình thấp/cỡ chữ lớn. |
| [dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart](../lib/screen/dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart) | Giữ các boundary sẵn có; bổ sung cleanup image/codec và xử lý tải xong sau dispose. |
| [dragon_panda/screens/boss_battle/boss_battle_intro_screen.dart](../lib/screen/dragon_panda/screens/boss_battle/boss_battle_intro_screen.dart) | Tách BossBattleIntroHeader/IntroductionCard; màn hình sở hữu viewport cuộn, background và callback bắt đầu/quay lại. |
| [dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart](../lib/screen/dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart) | Tách BossVictoryContent; Wrap phần thưởng và viewport cuộn hỗ trợ cỡ chữ lớn/màn hình thấp; giữ callback. |
| [dragon_panda/screens/chinese_restaurant/chinese_restaurant_screen.dart](../lib/screen/dragon_panda/screens/chinese_restaurant/chinese_restaurant_screen.dart) | Dùng GameScreenHeader; tách food card. |
| [dragon_panda/screens/game_hub/game_hub_screen.dart](../lib/screen/dragon_panda/screens/game_hub/game_hub_screen.dart) | Dùng HomeTabScaffold chung; giữ GameHubView thuần trình bày và callback chọn game/tab của bản preview. |
| [dragon_panda/screens/home/home_screen.dart](../lib/screen/dragon_panda/screens/home/home_screen.dart) | Dùng HomeTabScaffold chung; màn hình truyền background, HomeDashboard và callback điều hướng rõ ràng. |
| [dragon_panda/screens/quick_answer/quick_answer_screen.dart](../lib/screen/dragon_panda/screens/quick_answer/quick_answer_screen.dart) | Dùng GameScreenHeader với callback; giữ answer button có sẵn. |
| [dragon_panda/screens/radical_builder/radical_builder_screen.dart](../lib/screen/dragon_panda/screens/radical_builder/radical_builder_screen.dart) | Dùng GameScreenHeader; tách radical option tile. |
| [dragon_panda/screens/tone_ninja/tone_ninja_screen.dart](../lib/screen/dragon_panda/screens/tone_ninja/tone_ninja_screen.dart) | Dùng GameScreenHeader; tách tone option card. |
| [duolingo/duo_game_center_screen.dart](../lib/screen/duolingo/duo_game_center_screen.dart) | Tách DuoGameCard; giữ điều hướng và refresh tại màn hình. |
| [duolingo/page/duo_game_path_screen.dart](../lib/screen/duolingo/page/duo_game_path_screen.dart) | Tách header và path item; giữ SliverList lazy và key theo level ID. |
| [duolingo/page/duo_game_runner_screen.dart](../lib/screen/duolingo/page/duo_game_runner_screen.dart) | Tách feedback; dùng key theo challenge ID; bảo toàn trạng thái nối từ khi input tương đương. |
| [flashcards/flashcards_screen.dart](../lib/screen/flashcards/flashcards_screen.dart) | Tách mặt trước/sau, trạng thái rỗng/hoàn thành; controller tải deck/rating; State giữ animation và chặn đáp án trùng. |
| [game_hub/game_hub_screen.dart](../lib/screen/game_hub/game_hub_screen.dart) | Dùng HomeTabScaffold chung; tách luồng Boss Battle thành các hàm điều hướng riêng; giữ nhánh embedded và hành vi replay/thoát. |
| [hanzi_writing/screens/hanzi_writing_home_screen.dart](../lib/screen/hanzi_writing/screens/hanzi_writing_home_screen.dart) | Tách item chữ Hán; controller tìm kiếm bỏ kết quả cũ; State sở hữu input, bộ lọc và debounce. |
| [hanzi_writing/screens/hanzi_writing_screen.dart](../lib/screen/hanzi_writing/screens/hanzi_writing_screen.dart) | Tách tiến trình, overlay hoàn thành và tổng kết; controller tải chữ/lưu điểm/tìm chữ tiếp theo; đồng bộ khi characterId thay đổi. |
| [history/history_screen.dart](../lib/screen/history/history_screen.dart) | Tách item và detail sheet; dùng HistoryItem thay dynamic ở boundary. |
| [home/home_screen.dart](../lib/screen/home/home_screen.dart) | Giữ identity của các tab; tách practice tab và rail dùng chung cho tablet/desktop. |
| [hsk/hsk_screen.dart](../lib/screen/hsk/hsk_screen.dart) | Controller được đăng ký một lần; card nhận số liệu, quyền mở khóa và callback. |
| [hsk_exam/hsk_exam_screen.dart](../lib/screen/hsk_exam/hsk_exam_screen.dart) | Tách setup, câu hỏi và kết quả; snapshot Rx trong Obx trước khi truyền xuống. |
| [hsk_quiz/hsk_quiz_screen.dart](../lib/screen/hsk_quiz/hsk_quiz_screen.dart) | Tách setup/câu hỏi/kết quả; domain sinh câu hỏi; controller quản lý bài thi/đáp án; State dispose Worker/TTS và controller riêng. |
| [learning_overview/learning_overview_screen.dart](../lib/screen/learning_overview/learning_overview_screen.dart) | Tách activity tile; đăng ký controller ngoài build. |
| [lessons/lessons_screen.dart](../lib/screen/lessons/lessons_screen.dart) | Tách topic, hội thoại, từ vựng và ngữ pháp; Obx riêng cho selector/danh sách. |
| [quiz/quiz_screen.dart](../lib/screen/quiz/quiz_screen.dart) | Tách câu hỏi/kết quả; dùng BottomActionBar; đăng ký controller ngoài build. |
| [review/review_screen.dart](../lib/screen/review/review_screen.dart) | Tách item ôn tập; dùng BottomActionBar; giữ callback điều hướng. |
| [speaking/speaking_screen.dart](../lib/screen/speaking/speaking_screen.dart) | Controller có tag riêng cho mỗi instance và cleanup; Obx riêng cho nội dung, micro và kết quả. |
| [splash/splash_screen.dart](../lib/screen/splash/splash_screen.dart) | Tách SplashBranding/SplashLoadStatus nhận animation/error/callback; Obx riêng cho trạng thái; viewport cuộn hỗ trợ lỗi dài; State giữ lifecycle animation. |
| [stats/stats_screen.dart](../lib/screen/stats/stats_screen.dart) | Tách summary; đăng ký controller ngoài build. |
| [subscription/page/subscription_page.dart](../lib/screen/subscription/page/subscription_page.dart) | Gom định nghĩa gói bất biến, dựng PackageCard bằng một adapter; tách PurchasePendingOverlay có semantics; giữ controller mượn/Worker cleanup; badge gói đang dùng cho phép wrap. |
| [system/profile_page.dart](../lib/screen/system/profile_page.dart) | Tách phần thành tích; giữ Future, RouteObserver và lifecycle của màn hình. |
| [unit/unit_screen.dart](../lib/screen/unit/unit_screen.dart) | Card nhận số liệu/callback; cache future trong controller; tránh query lặp khi rebuild. |
| [word_detail/word_detail_screen.dart](../lib/screen/word_detail/word_detail_screen.dart) | Tách pronunciation/example card; dùng BottomActionBar; giữ điều hướng phát âm/luyện viết. |
| [word_list/word_list_screen.dart](../lib/screen/word_list/word_list_screen.dart) | Đăng ký controller ngoài build; Obx riêng cho progress/actions; giữ PageController và PageView. |

## Bổ sung helper method cho toàn project

Sau khi cập nhật skill `ui-architecture` với quy tắc helper method, đã áp dụng tiếp cho **38/38 file màn hình** và **17 file UI bổ trợ** (tổng 55 file Dart). `build()` thể hiện bố cục tổng thể; các khối giao diện có trách nhiệm riêng được chuyển sang `_build...`, còn xử lý tương tác phù hợp được chuyển sang `_handle...`. Các widget nhỏ đã có trách nhiệm rõ ràng tiếp tục giữ cách viết trực tiếp.

- Các màn học tập tách bộ lọc, progress, danh sách, nội dung câu hỏi và hành động; HSK/unit vẫn dùng Future đã cache, các lần đọc Rx vẫn nằm trong callback `Obx` tương ứng.
- Home tách bố cục mobile/rail; đường học Duolingo giữ builder lazy và key, màn chơi chọn gameplay bằng helper; các bài nối từ/xếp câu giữ State và lifecycle hiện tại.
- Boss Battle và bốn mini game tách arena, HUD, câu hỏi, bộ đáp án và nội dung kết quả. Helper trả `List<Widget>` dùng spread khi cần giữ nguyên các con trực tiếp của `Row`/`Stack`.
- Luyện viết tách canvas, header, feedback, bảng điểm và hành động tổng kết. Gesture, painter, animation/listenable và tài nguyên vẫn giữ nguyên chủ sở hữu.
- Các widget từ điển, câu hỏi/kết quả Quiz, HSK Exam, thành tích, navigation và dialog nâng cấp tách các khối trình bày. UI kết nối ban đầu trong `main.dart` cũng được chia helper.
- Skill phân biệt rõ helper method với widget boundary: helper không tạo Element, lifecycle hay phạm vi rebuild mới, không khởi tạo controller/tài nguyên hoặc gọi dịch vụ trong lúc build.

Lượt helper này đã format cả 55 file UI, chạy lại toàn bộ **88 test** thành công, và đối chiếu analyzer theo loại diagnostic/nội dung/file: **146 diagnostic như trước lượt helper, không thêm diagnostic mới**. So sánh **32 cặp ảnh render** ở 440 × 956 và 1000 × 956 cho 12 màn hình (bốn mini game, Boss intro/defeat/victory, Home/Game Hub preview, Game Hub chính, Splash, Subscription) và bốn view (Quiz câu hỏi, HSK Quiz kết quả, HSK Exam kết quả, Dictionary entry): tất cả khớp từng pixel. Bản trước refactor bao gồm cả các widget phụ thuộc được thay đổi; harness tạm được gỡ sau kiểm tra.

## Kiểm tra

- `flutter test`: 88 test qua, gồm 47 test mới cho callback, trạng thái disabled/empty, text scaling, identity, controller cleanup/concurrency và sinh câu hỏi.
- So sánh ảnh render trước/sau của Quick Answer, Radical Builder, Tone Ninja và Chinese Restaurant: khớp từng pixel ở 440 × 956 và 1000 × 956. Harness tạm dùng font của dự án, chờ tải đầy đủ asset và được gỡ sau khi kiểm tra.
- So sánh bổ sung cả 8 màn hình trước đó giữ nguyên: Boss intro/defeat/victory, Home/Game Hub preview, Game Hub chính, Splash và Subscription. Cả 16 phép so sánh tại 440 × 956 và 1000 × 956 khớp từng pixel; harness tạm được gỡ sau kiểm tra.
- 16 test hồi quy bổ sung kiểm tra callback/điều hướng, màn hình thấp, text scaling 150%, lỗi Splash dài, giá/lựa chọn gói và lớp chặn thao tác khi thanh toán, controller mượn sau dispose.
- Các test Home/Game Hub hiện có tiếp tục kiểm tra nhiều chiều rộng, safe area, chuyển tab và cập nhật stats.
- `flutter analyze`: không có lỗi compile và không thêm diagnostic mới so với trạng thái trước refactor; còn 146 diagnostic có sẵn (baseline: 166), chủ yếu API deprecated và lint/cảnh báo cũ. Vì vậy lệnh vẫn trả exit code 1; đây không phải lượt analyze sạch hoàn toàn.
- Khai báo trực tiếp `shared_preferences` vốn được code ứng dụng và test sử dụng; giữ nguyên phiên bản 2.5.5 trong lockfile.
- Đã format các file Dart thay đổi và chạy `git diff --check`.

Kiểm tra dùng Flutter test và dữ liệu giả; chưa chạy end-to-end các dịch vụ AI/Supabase, microphone/audio native hoặc mua hàng trên thiết bị.
