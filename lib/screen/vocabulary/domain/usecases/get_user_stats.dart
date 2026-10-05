import '../../data/models/user_stats_model.dart';
import '../repositories/user_stats_repository.dart';

class GetUserStatsUseCase {
  final UserStatsRepository repository;

  GetUserStatsUseCase({required this.repository});

  Future<UserStats> call() async {
    await repository.resetStreakIfNeeded();
    return await repository.getUserStats();
  }
}
