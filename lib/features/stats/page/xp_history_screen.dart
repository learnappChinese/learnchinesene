import 'package:flutter/material.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';

import '../../../core/learning/data/learning_history_repository.dart';
import '../../../core/learning/service/learning_progress_sync_service.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/learning_scaffold.dart';

class XpHistoryScreen extends StatefulWidget {
  const XpHistoryScreen({
    super.key,
    this.historyRepository,
  });

  final LearningHistoryRepository? historyRepository;

  @override
  State<XpHistoryScreen> createState() => _XpHistoryScreenState();
}

class _XpHistoryScreenState extends State<XpHistoryScreen> {
  late final LearningHistoryRepository _repo;
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];
  String _selectedFilter = 'all';
  LearningSyncRegistration? _syncRegistration;
  int _loadRequest = 0;

  final List<Map<String, String>> _filters = const [
    {'id': 'all', 'label': 'Tất cả'},
    {'id': 'vocabulary', 'label': 'Từ vựng'},
    {'id': 'listening', 'label': 'Luyện nghe'},
    {'id': 'speaking', 'label': 'Luyện nói'},
    {'id': 'hanzi', 'label': 'Chữ Hán'},
    {'id': 'boss', 'label': 'Boss'},
    {'id': 'quiz', 'label': 'Game phản xạ'},
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.historyRepository ?? SupabaseLearningHistoryRepository();
    if (Get.isRegistered<LearningProgressSyncService>()) {
      _syncRegistration =
          Get.find<LearningProgressSyncService>().registerRefresher(
        owner: 'xp-history',
        domains: const <LearningDomain>{
          LearningDomain.history,
          LearningDomain.identity,
        },
        refresh: (event) async {
          if (event.type == LearningDomainEventType.identityChanged &&
              mounted) {
            setState(() => _events = []);
          }
          await _loadEvents(rethrowFailure: true, silent: _events.isNotEmpty);
        },
      );
    }
    _loadEvents();
  }

  @override
  void dispose() {
    _loadRequest++;
    _syncRegistration?.dispose();
    super.dispose();
  }

  Future<void> _loadEvents({
    bool rethrowFailure = false,
    bool silent = false,
  }) async {
    final request = ++_loadRequest;
    if (!silent) setState(() => _isLoading = true);
    try {
      final list = await _repo.fetchFullXpLedger(
        limit: 100,
        filterType: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      if (mounted && request == _loadRequest) {
        setState(() {
          _events = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && request == _loadRequest) {
        setState(() => _isLoading = false);
      }
      if (rethrowFailure) rethrow;
    }
  }

  void _onFilterChanged(String filterId) {
    if (_selectedFilter == filterId) return;
    setState(() => _selectedFilter = filterId);
    _loadEvents();
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse('$raw').toLocal();
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      final date =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      return '$time • $date';
    } catch (_) {
      return '$raw';
    }
  }

  String _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'boss':
        return '🐲';
      case 'vocabulary':
        return '📖';
      case 'listening':
        return '🎧';
      case 'speaking':
        return '🎙️';
      case 'hanzi':
        return '✍️';
      case 'quiz':
        return '⚡';
      case 'review':
        return '🔄';
      case 'dialogue':
      case 'sentence':
        return '💬';
      default:
        return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Lịch sử Kinh nghiệm (XP)',
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.contentMaxWidth(context),
          ),
          child: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: _isLoading
                    ? const _XpHistorySkeleton()
                    : _events.isEmpty
                        ? _buildEmptyState()
                        : _buildEventList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.horizontalPadding(context),
        ),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['id'];
          return ChoiceChip(
            label: Text(
              filter['label']!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            selected: isSelected,
            selectedColor: GameVisualTokens.imperialGold,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? GameVisualTokens.imperialGold
                  : const Color(0xFFCBD5E1),
            ),
            onSelected: (_) => _onFilterChanged(filter['id']!),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('📜', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu XP cho bộ lọc này',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Hãy hoàn thành thêm các ải học hoặc mini-game để ghi danh vào sổ điểm!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.horizontalPadding(context),
        vertical: 12,
      ),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final event = _events[index];
        final xpAmount = (event['xp_amount'] as num?)?.toInt() ?? 0;
        final activityType = '${event['activity_type'] ?? 'learning'}';
        final reason = '${event['reason'] ?? 'Hoàn thành thử thách'}';
        final rawTime = event['created_at'];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: GameVisualTokens.imperialGold.withValues(alpha: 0.35),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameVisualTokens.imperialGold.withValues(alpha: 0.15),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getActivityIcon(activityType),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTimestamp(rawTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: GameVisualTokens.imperialGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GameVisualTokens.imperialGold,
                    width: 1,
                  ),
                ),
                child: Text(
                  '+$xpAmount XP',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Khung đang tải khớp danh sách sự kiện XP: icon tròn, hai dòng, pill XP.
class _XpHistorySkeleton extends StatelessWidget {
  const _XpHistorySkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.horizontalPadding(context),
            vertical: 8,
          ),
          itemCount: 12,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const SkeletonListTile(
            leadingSize: 44,
            leadingCircle: true,
            trailingPillWidth: 64,
            radius: 16,
          ),
        ),
      );
}
