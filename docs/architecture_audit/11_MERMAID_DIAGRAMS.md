# BÁO CÁO KIỂM TOÁN KIẾN TRÚC & DỮ LIỆU TOÀN DIỆN (FULL APPLICATION LOGIC & DATA AUDIT)
## 11. TẬP HỢP TOÀN BỘ SƠ ĐỒ HỆ THỐNG MERMAID (MERMAID SYSTEM DIAGRAMS)

> **Mục tiêu**: Tập hợp trực quan hóa toàn bộ hệ thống Pandarin từ mã nguồn và cấu trúc cơ sở dữ liệu thực tế: Kiến trúc ứng dụng, cây điều hướng, các luồng tương tác người dùng trọng yếu, sơ đồ thực thể liên kết dữ liệu (ERD), máy trạng thái trò chơi (Game State Machine) và luồng đồng bộ dữ liệu hai tầng (Data Sync Pipeline).

---

### Sơ đồ A: Kiến trúc Ứng dụng Thực tế (Application Architecture)

Mô hình kiến trúc GetX 3 tầng kết hợp Dual-Persistence (Supabase Server-Authoritative & SharedPreferences Client-Authoritative):

```mermaid
flowchart TB
    subgraph UI_Layer["1. GIAO DIỆN NGƯỜI DÙNG (PRESENTATION LAYER)"]
        direction TB
        V_Home["HomePage / HomeContent<br>Tab 0: Tiến độ, Unit, Quick Actions"]
        V_Learn["LearningJourneyPage<br>Tab 1: Lộ trình HSK 1-6 & Stage Node"]
        V_Review["ReviewPage<br>Tab 2: Ôn tập Flashcards SRS & Quản lý từ"]
        V_Tools["ToolsPage<br>Tab 3: AI Speaking, Hanzi, HSK Exam, Dict"]
        V_Profile["ProfilePage<br>Tab 4: Cài đặt, Đăng nhập, Thống kê XP"]
        V_Game["GameHubScreen / BossGameplay<br>Minigames: Tone Ninja, Word Match, Game Hub Boss"]
        V_Stage["StagePlayScreen / LessonScreen<br>Duo Runner: Multiple Choice, Listen, Order, Match"]
        V_Boss["BossBattleScreen<br>Curriculum Boss Battle (StatefulWidget)"]
    end

    subgraph State_DI_Layer["2. TẦNG QUẢN LÝ TRẠNG THÁI & DI (GETX CONTROLLERS & BINDINGS)"]
        direction TB
        C_Main["MainTabController<br>(Permanent)"]
        C_Auth["AuthController<br>(Permanent: Rx<User?>)"]
        C_Home["HomeController<br>(Fenix: true: streak, dailyGoal, stats)"]
        C_Journey["LearningJourneyController<br>(Fenix: true: units, stages, activeStage)"]
        C_Review["ReviewController<br>(Route-scoped: SRS queue, card flip)"]
        C_Stage["StagePlayController<br>(Route-scoped: hearts, score, streak, timer)"]
        C_BossOrphan["BossBattleController<br>(Orphaned / Unused by UI)"]
        C_Tools["HanziWritingController / SpeakingController / ToolsController"]
    end

    subgraph Domain_Service_Layer["3. TẦNG NGHIỆP VỤ & ĐỒNG BỘ (SERVICES & DOMAIN REPOSITORIES)"]
        direction TB
        S_Sync["LearningProgressSyncService<br>(Bus Broadcast Invalidation: bumpStageSync, bumpUnitSync)"]
        S_Reward["LearningRewardService<br>(Transaction Processor: processReward, processBossReward)"]
        S_Audio["AudioService & TtsService<br>(Audioplayers remote URL & FlutterTts fallback)"]
        S_Speech["SpeechService & GeminiAiService<br>(SpeechToText microphone & Supabase Edge Function gateway)"]
        R_Unit["LearningUnitRepository & LearningStageRepository"]
        R_Vocab["VocabularyRepository & FlashcardRepository"]
    end

    subgraph Data_Persistence_Layer["4. TẦNG DỮ LIỆU & LƯU TRỮ (DUAL-PERSISTENCE LAYER)"]
        direction TB
        subgraph Cloud_Supabase["Supabase Cloud (PostgreSQL 15)"]
            DB_Lexicon[("lexicon_words / lexicon_characters")]
            DB_Duo[("duo_units / duo_stages / duo_challenges / duo_options")]
            DB_Progress[("duo_level_progress / duo_active_sessions")]
            DB_Ledger[("learning_xp_events / learning_attempts / app_user_stats")]
            DB_RPC[["RPCs: duo_complete_stage_transaction_v2 / duo_record_boss_reward_v2"]]
        end

        subgraph Local_Storage["Thiết bị cục bộ (Local Client)"]
            SP_Pref[("SharedPreferences<br>guest_learning_*, duo_game_session_*")]
            FS_Log[("Local File: history_logs.json<br>AI Dictionary & HSK Exam Logs")]
            RAM_Mem[("Volatile RAM State<br>GameHubScreen.currentBossStageLevel")]
        end
    end

    %% UI to Controller bindings
    V_Home --> C_Home
    V_Learn --> C_Journey
    V_Review --> C_Review
    V_Tools --> C_Tools
    V_Profile --> C_Auth
    V_Stage --> C_Stage
    V_Boss -.->|KHÔNG SỬ DỤNG| C_BossOrphan
    V_Boss --> S_Reward

    %% Controller to Services
    C_Stage --> S_Reward
    C_Stage --> S_Audio
    C_Stage --> S_Sync
    C_Journey --> R_Unit
    C_Journey --> S_Sync
    C_Review --> R_Vocab
    C_Review --> S_Audio
    C_Tools --> S_Speech

    %% Services to Repositories & Invalidation Loop
    S_Reward --> S_Sync
    S_Sync -.->|Lắng nghe Stream / Event| C_Journey
    S_Sync -.->|Lắng nghe Stream / Event| C_Home

    %% Services to Data Sources
    S_Reward -->|Authenticated User| DB_RPC
    S_Reward -->|Guest Mode| SP_Pref
    R_Unit --> DB_Duo
    R_Unit --> DB_Progress
    R_Vocab --> DB_Lexicon
    S_Speech -->|Edge Function| Cloud_Supabase
    C_Tools --> FS_Log
    V_Game --> RAM_Mem
```

---

### Sơ đồ B: Cây Điều hướng Ứng dụng (Screen Navigation Tree)

```mermaid
flowchart TD
    Start([Khởi động Ứng dụng]) --> Splash[SplashScreen<br>lib/features/splash/splash_screen.dart]
    
    Splash --> SplashCtrl{Kiểm tra Auth<br>SplashController}
    SplashCtrl -->|Khách mặc định: continueAsGuest| MainTab[MainTabView: 5 Persistent Tabs<br>lib/core/navigation/main_tab_view.dart]
    SplashCtrl -->|Session Supabase tồn tại| MainTab

    %% 5 Persistent Tabs
    subgraph TabView["MainTabView (IndexedStack / Scaffold)"]
        Tab0["Tab 0: Home<br>HomePage"]
        Tab1["Tab 1: Học tập<br>LearningJourneyPage"]
        Tab2["Tab 2: Ôn tập<br>ReviewPage"]
        Tab3["Tab 3: Công cụ AI<br>ToolsPage"]
        Tab4["Tab 4: Cá nhân<br>ProfilePage"]
    end

    MainTab --> Tab0
    MainTab --> Tab1
    MainTab --> Tab2
    MainTab --> Tab3
    MainTab --> Tab4

    %% Tab 0: Home Routes
    Tab0 -->|Nhấn Game Hub Banner| GameHub[GameHubScreen<br>lib/features/dragon_panda/screens/game_hub_screen.dart]
    Tab0 -->|Nhấn Quick Review Card| ReviewSession[ReviewSessionScreen<br>lib/features/review/review_session_screen.dart]
    Tab0 -->|Nhấn Tiếp tục học| UnitOverview[UnitOverviewScreen<br>lib/features/learning/unit_overview_screen.dart]

    %% Tab 1: Journey Routes
    Tab1 -->|Chọn Unit| UnitOverview
    UnitOverview -->|Nhấn vào Stage Node| StagePlay[StagePlayScreen<br>lib/features/learning/stage_play_screen.dart]
    UnitOverview -->|Nhấn vào Boss Node| BossCurriculum[BossBattleScreen<br>lib/features/boss_battle/boss_battle_screen.dart]
    StagePlay -->|Hoàn thành ải| StageComplete[StageCompleteDialog / BottomSheet]
    StageComplete -->|Trở về| UnitOverview
    BossCurriculum -->|Hạ Boss thành công| UnitComplete[UnitCompleteScreen<br>lib/features/learning/unit_complete_screen.dart]
    UnitComplete -->|Nhấn Sang Unit kế tiếp| NextUnitOverview[UnitOverviewScreen: Unit Kế tiếp<br>⚠️ Rò rỉ Stack: Get.off thay vì Get.offAll]

    %% Tab 2: Review Routes
    Tab2 -->|Bắt đầu ôn tập| ReviewSession
    Tab2 -->|Chi tiết từ đã nhớ| WordDetail[WordDetailModal / Dialog]

    %% Tab 3: Tools Routes
    Tab3 -->|Luyện viết Chữ Hán| HanziWrite[HanziWritingScreen<br>lib/features/tools/hanzi_writing_screen.dart]
    Tab3 -->|Luyện phát âm AI| SpeakingPrac[SpeakingScreen<br>lib/features/tools/speaking_screen.dart]
    Tab3 -->|Thi thử HSK| HskExam[HskExamScreen<br>lib/features/tools/hsk_exam_screen.dart]
    Tab3 -->|Hội thoại thông minh| ChatAi[AiConversationScreen<br>lib/features/tools/ai_conversation_screen.dart]
    Tab3 -->|Tra cứu từ điển| DictSearch[DictionarySearchScreen<br>lib/features/tools/dictionary_search_screen.dart]

    %% Tab 4: Profile Routes
    Tab4 -->|Nhấn Đăng nhập| LoginSheet[AuthModalBottomSheet / LoginScreen]
    Tab4 -->|Góp ý báo lỗi| FeedbackSheet[FeedbackModalBottomSheet]

    %% Game Hub Sub-routes
    GameHub -->|Chơi Boss Rồng| BossGameHub[BossBattleGameplayScreen<br>lib/features/dragon_panda/screens/boss_battle/...<br>⚠️ KHÔNG LƯU TIẾN ĐỘ / 0 XP]
    GameHub -->|Ninja Chém Tone| ToneNinja[ToneNinjaScreen]
    GameHub -->|Nối Từ Hán Tự| WordMatch[WordMatchScreen]

    %% Orphaned Screens
    subgraph Orphaned["Mã nguồn mồ côi (Không thể truy cập từ UI)"]
        Orphan1[BossStageMapScreen]
        Orphan2[LearningOverviewScreen]
        Orphan3[WordListScreen]
    end
```

---

### Sơ đồ C: Luồng Tương tác Người dùng Trọng yếu (User Interaction Flows)

#### C.1. Luồng Học Ải Tiêu chuẩn (Stage Quiz Flow)

```mermaid
sequenceDiagram
    autonumber
    actor User as Học viên
    participant Screen as StagePlayScreen
    participant Ctrl as StagePlayController
    participant Reward as LearningRewardService
    participant Sync as LearningProgressSyncService
    participant DB as Supabase RPC / SharedPreferences

    User->>Screen: Nhấn chọn đáp án A/B/C/D
    Screen->>Ctrl: selectOption(optionId)
    User->>Screen: Nhấn nút "Kiểm tra" (Check Answer)
    Ctrl->>Ctrl: validateAnswer(selectedOption)
    
    alt Đáp án ĐÚNG
        Ctrl->>Screen: Play sound 'correct.mp3' & Show BottomSheet Xanh (+XP, +Streak)
    else Đáp án SAI
        Ctrl->>Ctrl: Trừ 1 Tim (hearts - 1) & Thêm vào incorrectQueue
        Ctrl->>Screen: Play sound 'wrong.mp3' & Camera Shake & Show BottomSheet Đỏ
    end

    User->>Screen: Nhấn "Tiếp tục"
    
    alt Chưa hết câu hỏi
        Ctrl->>Screen: loadNextChallenge() (Render câu tiếp theo)
    else Đã hết câu hỏi chính
        opt Còn câu hỏi sai trong incorrectQueue
            Ctrl->>Screen: Re-render câu sai cho đến khi trả lời đúng
        end
        User->>Screen: Hoàn thành câu cuối cùng
        Screen->>Reward: processReward(stageId, score, duration)
        
        alt Người dùng đã Đăng nhập (Auth)
            Reward->>DB: rpc('duo_complete_stage_transaction_v2', params)
            DB-->>Reward: { success: true, xp_gained: 20, is_unlocked: true }
        else Khách vãng lai (Guest)
            Reward->>DB: SharedPreferences.setStringList('guest_learning_completed_stages_v1')
            Reward->>DB: SharedPreferences.setStringList('guest_learning_xp_events_v2')
            DB-->>Reward: Lưu trữ cục bộ thành công
        end
        
        Reward->>Sync: notifyStageCompleted(stageId)
        Sync-->>Screen: Bắn Event Invalidation (bumpStageSync)
        Screen->>User: Hiển thị StageCompleteDialog (Nhận XP, Sao, Tỷ lệ chính xác)
    end
```

#### C.2. Luồng Hạ Boss Giáo trình (Curriculum Boss Battle Flow)

```mermaid
sequenceDiagram
    autonumber
    actor User as Học viên
    participant Screen as BossBattleScreen (StatefulWidget)
    participant Audio as FlutterTts / AudioPlayer
    participant Reward as LearningRewardService
    participant Sync as LearningProgressSyncService
    participant DB as Supabase RPC: duo_record_boss_reward_v2

    User->>Screen: Mở màn đấu Boss Unit
    Screen->>Screen: Khởi tạo Boss HP (100) & Player HP (100)
    
    loop Vòng lặp Đối kháng (Turns)
        Screen->>Audio: Phát âm câu hỏi Pinyin / Audio
        User->>Screen: Chọn đòn tấn công / Trả lời trắc nghiệm
        alt Người chơi trả lời ĐÚNG
            Screen->>Screen: Boss HP -= 25 & Kích hoạt Animation Trúng đòn Boss
        else Người chơi trả lời SAI
            Screen->>Screen: Player HP -= 20 & Camera Shake màn hình
        end
    end

    alt Boss HP <= 0 (Chiến thắng)
        Screen->>Reward: processBossReward(unitId, bossId, score)
        alt User Signed-in
            Reward->>DB: call rpc('duo_record_boss_reward_v2', unitId, score)
            DB-->>Reward: { success: true, unit_unlocked: nextUnitId, xp: 50 }
        else Guest Mode
            Reward->>Reward: Ghi SharedPreferences('guest_learning_completed_bosses_v1')
        end
        Reward->>Sync: notifyUnitCompleted(unitId)
        Screen->>User: Chuyển hướng sang UnitCompleteScreen
    else Player HP <= 0 (Thất bại)
        Screen->>User: Hiển thị Thua trận (Defeat Dialog), Cho phép Thử lại
    end
```

---

### Sơ đồ D: Sơ đồ Thực thể Liên kết Dữ liệu (Database ERD)

```mermaid
erDiagram
    %% Auth & User Profile
    auth_users ||--o{ app_user_stats : "1-to-1 Profile stats"
    auth_users ||--o{ learning_xp_events : "1-to-many Ledger events"
    auth_users ||--o{ learning_attempts : "1-to-many Question history"
    auth_users ||--o{ duo_level_progress : "1-to-many Stage progress"
    auth_users ||--o{ duo_active_sessions : "1-to-many Active sessions"
    auth_users ||--o{ user_vocabulary_progress : "1-to-many SRS Flashcard state"

    %% Curriculum Hierarchy
    duo_units ||--o{ duo_stages : "contains 1..n stages"
    duo_stages ||--o{ duo_challenges : "contains 1..n challenges"
    duo_challenges ||--o{ duo_options : "contains 2..4 options"
    duo_challenges }o--o| lexicon_words : "references target word"

    %% Progress & History Tracking
    duo_stages ||--o{ duo_level_progress : "tracked by"
    duo_stages ||--o{ duo_active_sessions : "holds state in"
    duo_stages ||--o{ learning_attempts : "recorded in"

    %% Vocabulary & Characters
    lexicon_words }o--o{ lexicon_characters : "composed of"
    lexicon_words ||--o{ user_vocabulary_progress : "user SRS mastery"

    auth_users {
        uuid id PK
        string email
        timestamp created_at
    }

    app_user_stats {
        uuid user_id PK, FK
        integer total_xp
        integer current_streak
        integer longest_streak
        integer words_learned
        timestamp last_active_at
    }

    duo_units {
        uuid id PK
        integer hsk_level
        integer unit_order
        string title
        string description
        string icon_url
        integer required_stars
    }

    duo_stages {
        uuid id PK
        uuid unit_id FK
        integer stage_order
        string title
        string stage_type
        integer reward_xp
        integer pass_score
    }

    duo_challenges {
        uuid id PK
        uuid stage_id FK
        uuid word_id FK
        string challenge_type
        text prompt
        text translation
        string audio_url
        integer order_index
    }

    duo_options {
        uuid id PK
        uuid challenge_id FK
        text content
        text translation
        boolean is_correct
        integer order_index
    }

    duo_level_progress {
        uuid id PK
        uuid user_id FK
        uuid stage_id FK
        boolean is_completed
        integer stars
        integer highest_score
        timestamp completed_at
    }

    learning_xp_events {
        uuid id PK
        uuid user_id FK
        integer xp_amount
        string source_type
        string source_id
        timestamp created_at
    }

    learning_attempts {
        uuid id PK
        uuid user_id FK
        uuid stage_id FK
        uuid challenge_id FK
        boolean is_correct
        integer time_spent_ms
        timestamp attempted_at
    }

    lexicon_words {
        uuid id PK
        string simplified
        string traditional
        string pinyin
        string meaning_vi
        integer hsk_level
        string tts_url
    }

    user_vocabulary_progress {
        uuid id PK
        uuid user_id FK
        uuid word_id FK
        integer srs_stage
        float ease_factor
        integer interval_days
        timestamp next_review_at
    }
```

---

### Sơ đồ E: Máy Trạng thái Trò chơi & Ải học (Game State Machine)

```mermaid
stateDiagram-v2
    [*] --> Initializing: Người dùng chọn Ải / Boss
    
    Initializing --> FetchingData: Kiểm tra Local Cache & Supabase
    FetchingData --> SessionReady: Tải câu hỏi & Khởi tạo Hearts (5)
    FetchingData --> NetworkError: Mất mạng & Không có Cache
    NetworkError --> Initializing: Retry

    state PlayingSession {
        [*] --> RenderingQuestion: Hiển thị Prompt & Options
        RenderingQuestion --> AudioPlaying: TtsService phát âm (nếu có)
        AudioPlaying --> WaitingInput: Chờ người dùng tương tác
        
        WaitingInput --> AnswerSelected: Học viên chọn đáp án
        AnswerSelected --> Validating: Nhấn nút "Kiểm tra"
        
        Validating --> EvaluationCorrect: Đáp án ĐÚNG
        EvaluationCorrect --> NextQuestion: Tích lũy Combo & XP (+10)
        
        Validating --> EvaluationWrong: Đáp án SAI
        EvaluationWrong --> HeartDeduction: Trừ 1 Tim & Rung camera
        HeartDeduction --> PushIncorrectQueue: Đẩy câu hỏi vào hàng đợi ôn lại
        PushIncorrectQueue --> NextQuestion: Còn tim (> 0)
        
        HeartDeduction --> OutOfHearts: Hết tim (= 0)
        NextQuestion --> RenderingQuestion: Chưa hết danh sách
        NextQuestion --> QueueClearing: Hết danh sách gốc nhưng còn câu sai
        QueueClearing --> RenderingQuestion: Luyện lại câu sai đến khi đúng
    }

    SessionReady --> PlayingSession: Bắt đầu bấm giờ
    
    PlayingSession --> Victory: Vượt qua tất cả câu hỏi
    OutOfHearts --> Defeat: Thua trận (Hết tim)
    PlayingSession --> Abandonment: Người dùng bấm Thoát giữa chừng

    state Victory {
        [*] --> CalculatingReward: Điểm số, Độ chính xác, Thời gian
        CalculatingReward --> PersistingData: Gọi LearningRewardService
        PersistingData --> CloudRPC: User đã đăng nhập -> Supabase RPC
        PersistingData --> LocalStorage: Khách vãng lai -> SharedPreferences
        CloudRPC --> SyncInvalidation: Bắn tín hiệu bumpStageSync
        LocalStorage --> SyncInvalidation: Bắn tín hiệu bumpStageSync
        SyncInvalidation --> DisplayVictoryUI: Hiển thị StageCompleteDialog / UnitComplete
    }

    state Defeat {
        [*] --> ShowDefeatDialog: Báo hết tim / Máu Boss còn
        ShowDefeatDialog --> RetrySession: Chọn Thử lại (Reset Tim/HP)
        ShowDefeatDialog --> ExitToOverview: Chọn Thoát ra ngoài
    }

    state Abandonment {
        [*] --> SaveInterimSession: Ghi duo_active_sessions (Chỉ Auth)
        SaveInterimSession --> ExitToOverview: Quay về UnitOverviewScreen
    }

    DisplayVictoryUI --> [*]: Trở về màn hình Lộ trình / Sang ải mới
    ExitToOverview --> [*]: Trở về UnitOverviewScreen
    RetrySession --> Initializing: Tải lại ải
```

---

### Sơ đồ F: Luồng Đồng bộ & Vòng lặp Hủy bộ nhớ đệm (Data Sync & Invalidation Flow)

```mermaid
sequenceDiagram
    autonumber
    participant UI_View as Màn hình Lộ trình (LearningJourneyPage)
    participant Ctrl_Journey as LearningJourneyController
    participant Service_Reward as LearningRewardService
    participant Service_Sync as LearningProgressSyncService
    participant Source_DB as Supabase Database / SharedPreferences
    participant Ctrl_Home as HomeController

    Note over UI_View, Ctrl_Home: BƯỚC 1: HỌC VIÊN HOÀN THÀNH BÀI HỌC HOẶC HẠ BOSS
    Service_Reward->>Source_DB: Ghi dữ liệu bền vững (RPC hoàn tất ải / Update SharedPreferences)
    Source_DB-->>Service_Reward: Xác nhận ghi thành công (Transaction OK)

    Note over Service_Reward, Service_Sync: BƯỚC 2: PHÁT TÍN HIỆU ĐỒNG BỘ TOÀN CỤC
    Service_Reward->>Service_Sync: notifyStageCompleted(stageId)
    Service_Sync->>Service_Sync: bumpStageSync() / bumpUnitSync() (Tăng Sequence Number)

    Note over Service_Sync, Ctrl_Journey: BƯỚC 3: CÁC CONTROLLER ĐANG SỐNG NHẬN SỰ KIỆN INVALIDATION
    par Đồng bộ Tiến độ Lộ trình
        Service_Sync-->>Ctrl_Journey: Stream Event: Stage Sync Bumped
        Ctrl_Journey->>Source_DB: Đọc lại danh sách ải đã mở khóa & đã học
        Source_DB-->>Ctrl_Journey: Trả về Map<stageId, isCompleted> mới nhất
        Ctrl_Journey->>Ctrl_Journey: Cập nhật RxMap stageProgress
        Ctrl_Journey-->>UI_View: Re-render Node trên bản đồ (Đổi màu sang Hoàn thành / Mở khóa tiếp theo)
    and Đồng bộ Trang chủ & Thống kê
        Service_Sync-->>Ctrl_Home: Stream Event: XP / Streak Changed
        Ctrl_Home->>Source_DB: Đọc lại app_user_stats / SharedPreferences
        Source_DB-->>Ctrl_Home: Trả về Total XP mới (+20 XP) & Current Streak
        Ctrl_Home->>Ctrl_Home: Cập nhật RxInt totalXp, RxInt currentStreak
        Ctrl_Home-->>UI_View: Cập nhật UI Header trang chủ ngay lập tức
    end
```
