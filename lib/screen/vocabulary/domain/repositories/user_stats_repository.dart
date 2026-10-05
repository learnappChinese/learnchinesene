
import '../../data/models/user_stats_model.dart';

abstract class UserStatsRepository {
  Future<UserStats> getUserStats();
  Future<void> updateUserStats(UserStats stats);
  Future<void> addExp(int exp);
  Future<void> updateStreak();
  Future<void> resetStreakIfNeeded();
  Future<void> updateWordsMastered(int count);
  Future<void> updateFavorites(int count);
}
