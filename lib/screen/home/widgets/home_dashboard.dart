import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../model/home_journey.dart';
import 'home_decorations.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.onStartLearning,
    required this.onGrammar,
    required this.onListening,
    required this.onSpeaking,
    required this.onChallenge,
    required this.onProgress,
    this.onReview,
    this.onViewAllQuickActions,
    this.onRefresh,
    this.onRetry,
    this.journey,
    this.isLoading = false,
    this.errorMessage,
    this.streak = 0,
    this.lessons = 0,
    this.xp = 0,
  });

  final VoidCallback onStartLearning;
  final VoidCallback onGrammar;
  final VoidCallback onListening;
  final VoidCallback onSpeaking;
  final VoidCallback onChallenge;
  final VoidCallback onProgress;
  final VoidCallback? onReview;
  final VoidCallback? onViewAllQuickActions;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetry;
  final HomeJourney? journey;
  final bool isLoading;
  final String? errorMessage;
  final int streak;
  final int lessons;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: GameVisualTokens.cream,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              Widget scroll = CustomScrollView(
                key: const PageStorageKey('home-dashboard'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < 360 ? 14 : 20,
                      12,
                      constraints.maxWidth < 360 ? 14 : 20,
                      120,
                    ),
                    sliver: SliverList.list(children: [
                      _JourneyTopBar(streak: streak, xp: xp),
                      const SizedBox(height: 16),
                      _buildHero(context),
                      const SizedBox(height: 18),
                      _QuestStrip(
                        learned: lessons,
                        onQuest: onChallenge,
                        onReview: onReview ?? onGrammar,
                      ),
                      const SizedBox(height: 14),
                      _AdventureActions(
                        streak: streak,
                        bossProgress: journey?.bossProgress ?? 0,
                        onReview: onReview ?? onListening,
                        onBoss: onProgress,
                        onSpeaking: onSpeaking,
                        onAll: onViewAllQuickActions ?? onStartLearning,
                      ),
                    ]),
                  ),
                ],
              );
              if (onRefresh != null) {
                scroll = RefreshIndicator(
                  color: GameVisualTokens.jade,
                  onRefresh: onRefresh!,
                  child: scroll,
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: scroll,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    if (isLoading) return const _JourneySkeleton();
    if (errorMessage != null) {
      return _JourneyMessage(
        icon: Icons.cloud_off_rounded,
        title: errorMessage!,
        action: 'THỬ LẠI',
        onTap: onRetry,
      );
    }
    if (journey == null) {
      return _JourneyMessage(
        icon: Icons.explore_rounded,
        title: 'Hành trình mới đang chờ bạn',
        action: 'KHÁM PHÁ THẾ GIỚI',
        onTap: onStartLearning,
      );
    }
    return _JourneyHero(journey: journey!, onContinue: onStartLearning);
  }
}

class _JourneyTopBar extends StatelessWidget {
  const _JourneyTopBar({required this.streak, required this.xp});
  final int streak;
  final int xp;

  @override
  Widget build(BuildContext context) => Row(children: [
        const HomePandaFace(size: 46),
        const SizedBox(width: 10),
        const Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('你好，NHÀ THÁM HIỂM!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text('Cuộc phiêu lưu hôm nay đã sẵn sàng',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: GameVisualTokens.muted, fontSize: 12)),
          ]),
        ),
        _Pill(icon: Icons.local_fire_department_rounded, label: '$streak'),
        const SizedBox(width: 6),
        _Pill(icon: Icons.bolt_rounded, label: '$xp XP'),
      ]);
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GameVisualTokens.goldLight),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 17, color: GameVisualTokens.orange),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      );
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({required this.journey, required this.onContinue});
  final HomeJourney journey;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            'Chương ${journey.chapterNumber}, nhiệm vụ ${journey.missionNumber}',
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: GameVisualTokens.jadeDark,
            borderRadius: BorderRadius.circular(28),
            boxShadow: GameVisualTokens.gameShadow,
          ),
          child: Stack(children: [
            Positioned.fill(
              child: Image.asset(homeSceneAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  color: const Color(0xB509302D),
                  colorBlendMode: BlendMode.multiply),
            ),
            Positioned(
              right: -15,
              bottom: 40,
              child: Image.asset(homeTitlePandaAsset,
                  width: 142, height: 142, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'THẾ GIỚI ${journey.worldNumber}  •  CHƯƠNG ${journey.chapterNumber}',
                        style: const TextStyle(
                            color: GameVisualTokens.goldLight,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 230,
                      child: Text(journey.chapterTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1.05,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 10),
                    Text('NHIỆM VỤ ${journey.missionNumber}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 11)),
                    SizedBox(
                      width: 215,
                      child: Text(journey.missionTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 20),
                    _ProgressLine(
                      value: journey.chapterProgress,
                      label:
                          '${journey.completedMissions}/${journey.totalMissions} nhiệm vụ',
                    ),
                    const SizedBox(height: 9),
                    Row(children: [
                      const Icon(Icons.card_giftcard_rounded,
                          color: GameVisualTokens.goldLight, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Phần thưởng tiếp theo: +${journey.nextRewardXp} XP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 17),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: onContinue,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('TIẾP TỤC HÀNH TRÌNH'),
                        style: FilledButton.styleFrom(
                          backgroundColor: GameVisualTokens.imperialGold,
                          foregroundColor: GameVisualTokens.ink,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w900, letterSpacing: .3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ]),
            ),
          ]),
        ),
      );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value, required this.label});
  final double value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Expanded(
            child: Text('TIẾN ĐỘ CHƯƠNG',
                maxLines: 1,
                style: TextStyle(color: Colors.white70, fontSize: 10)),
          ),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: value.clamp(0, 1),
            backgroundColor: Colors.black26,
            valueColor:
                const AlwaysStoppedAnimation(GameVisualTokens.imperialGold),
          ),
        ),
      ]);
}

class _QuestStrip extends StatelessWidget {
  const _QuestStrip(
      {required this.learned, required this.onQuest, required this.onReview});
  final int learned;
  final VoidCallback onQuest;
  final VoidCallback onReview;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.flag_rounded,
            title: 'Nhiệm vụ ngày',
            subtitle: 'Học 10 từ • ${learned.clamp(0, 10)}/10',
            color: GameVisualTokens.crimson,
            onTap: onQuest,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.replay_rounded,
            title: 'Ôn luyện',
            subtitle: 'Giữ ký ức luôn sắc bén',
            color: GameVisualTokens.jade,
            onTap: onReview,
          ),
        ),
      ]);
}

class _AdventureActions extends StatelessWidget {
  const _AdventureActions(
      {required this.streak,
      required this.bossProgress,
      required this.onReview,
      required this.onBoss,
      required this.onSpeaking,
      required this.onAll});
  final int streak;
  final double bossProgress;
  final VoidCallback onReview;
  final VoidCallback onBoss;
  final VoidCallback onSpeaking;
  final VoidCallback onAll;
  @override
  Widget build(BuildContext context) => Column(children: [
        _ActionCard(
            icon: Icons.shield_rounded,
            title: 'Cổng Boss',
            subtitle: '${(bossProgress * 100).round()}% sức mạnh đã tích lũy',
            color: GameVisualTokens.burgundy,
            onTap: onBoss),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _ActionCard(
                  icon: Icons.mic_rounded,
                  title: 'Luyện nói',
                  subtitle: 'Trò chuyện cùng NPC',
                  color: GameVisualTokens.orange,
                  onTap: onSpeaking)),
          const SizedBox(width: 10),
          Expanded(
              child: _ActionCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Chuỗi ngày',
                  subtitle: '$streak ngày phiêu lưu',
                  color: GameVisualTokens.imperialGold,
                  onTap: onAll)),
        ]),
      ]);
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: GameVisualTokens.muted, fontSize: 11)),
                  ])),
            ]),
          ),
        ),
      );
}

class _JourneySkeleton extends StatelessWidget {
  const _JourneySkeleton();
  @override
  Widget build(BuildContext context) => Container(
        height: 345,
        decoration: BoxDecoration(
            color: GameVisualTokens.creamStrong,
            borderRadius: BorderRadius.circular(28)),
        child: const Center(
            child: CircularProgressIndicator(color: GameVisualTokens.jade)),
      );
}

class _JourneyMessage extends StatelessWidget {
  const _JourneyMessage(
      {required this.icon,
      required this.title,
      required this.action,
      this.onTap});
  final IconData icon;
  final String title;
  final String action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: GameVisualTokens.softShadow),
        child: Column(children: [
          Icon(icon, size: 48, color: GameVisualTokens.jade),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          FilledButton(onPressed: onTap, child: Text(action)),
        ]),
      );
}
