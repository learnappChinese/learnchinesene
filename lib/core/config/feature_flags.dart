/// Cấu hình tính năng ứng dụng (Release Feature Flags).
///
/// Dùng để bật/tắt an toàn các phân hệ thử nghiệm hoặc tính năng AI
/// mà không làm thay đổi hoặc xóa mã nguồn.
abstract final class FeatureFlags {
  /// Bật/tắt các tính năng AI Generative (Gemini AI Conversation, AI Exam, AI Dictionary).
  /// Mặc định: FALSE trong phiên bản Local-First phát hành chính thức.
  static bool enableAi = false;

  /// Bật/tắt Game Hub (Minigames).
  /// Mặc định: FALSE trong luồng học chính thức HSK Local-First.
  static const bool enableGameHub = false;

  /// Bật/tắt chế độ đồng bộ Cloud (Chưa kích hoạt trong v1).
  static const bool enableCloudSync = false;
}
