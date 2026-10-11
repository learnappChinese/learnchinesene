import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/learning_activity_submission.dart';
import '../model/learning_result.dart';

enum LearningDomain {
  journey,
  unitPath,
  stats,
  history,
  mastery,
  review,
  profile,
  game,
  session,
  identity,
}

enum LearningDomainEventType {
  activityCompleted,
  bossCompleted,
  lexiconReviewed,
  sessionChanged,
  identityChanged,
  appResumed,
}

class LearningDomainEvent {
  const LearningDomainEvent({
    required this.type,
    required this.domains,
    this.generation = 0,
    this.unitId,
    this.levelId,
    this.identityKey,
    this.result,
    this.submission,
  });

  final LearningDomainEventType type;
  final Set<LearningDomain> domains;
  final int generation;
  final String? unitId;
  final String? levelId;
  final String? identityKey;
  final LearningResult? result;
  final LearningActivitySubmission? submission;

  LearningDomainEvent withGeneration(int value) => LearningDomainEvent(
        type: type,
        domains: domains,
        generation: value,
        unitId: unitId,
        levelId: levelId,
        identityKey: identityKey,
        result: result,
        submission: submission,
      );

  factory LearningDomainEvent.afterCompletion(
    LearningResult result,
    LearningActivitySubmission submission,
  ) {
    final activity = submission.activityType;
    final isBoss = activity == 'boss';
    final affectsReview = <String>{
      'review',
      'vocabulary',
      'listening',
      'speaking',
      'hanzi',
    }.contains(activity);

    return LearningDomainEvent(
      type: isBoss
          ? LearningDomainEventType.bossCompleted
          : activity == 'review'
              ? LearningDomainEventType.lexiconReviewed
              : LearningDomainEventType.activityCompleted,
      domains: <LearningDomain>{
        LearningDomain.journey,
        LearningDomain.unitPath,
        LearningDomain.stats,
        LearningDomain.history,
        LearningDomain.mastery,
        LearningDomain.profile,
        LearningDomain.game,
        LearningDomain.session,
        if (affectsReview) LearningDomain.review,
      },
      unitId: submission.unitId,
      levelId: submission.levelId,
      result: result,
      submission: submission,
    );
  }
}

class LearningSyncReport {
  const LearningSyncReport({
    required this.event,
    required this.refreshedOwners,
    required this.failures,
  });

  final LearningDomainEvent event;
  final Set<String> refreshedOwners;
  final Map<String, Object> failures;

  bool get isComplete => failures.isEmpty;
}

typedef LearningDomainRefresher = Future<void> Function(
  LearningDomainEvent event,
);

class LearningSyncRegistration {
  LearningSyncRegistration(this._onDispose);

  final void Function() _onDispose;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _onDispose();
  }
}

class LearningProgressSyncService extends GetxService {
  LearningProgressSyncService({
    SupabaseClient? client,
    this.maxRefreshAttempts = 2,
  })  : assert(maxRefreshAttempts > 0),
        _client = client {
    _identityKey.value = _client?.auth.currentUser?.id ?? 'guest';
    _authSubscription = _client?.auth.onAuthStateChange.listen((authState) {
      final nextIdentity = authState.session?.user.id ?? 'guest';
      if (nextIdentity == _identityKey.value) return;
      _identityKey.value = nextIdentity;
      unawaited(
        invalidate(
          LearningDomainEvent(
            type: LearningDomainEventType.identityChanged,
            domains: LearningDomain.values.toSet(),
            identityKey: nextIdentity,
          ),
        ),
      );
    });
  }

  final SupabaseClient? _client;
  final int maxRefreshAttempts;
  final _events = StreamController<LearningDomainEvent>.broadcast();
  final _subscribers = <int, _LearningSyncSubscriber>{};
  final _identityKey = 'guest'.obs;
  final _lastFailures = <String, String>{}.obs;
  final generation = 0.obs;
  final isSyncing = false.obs;

  StreamSubscription<AuthState>? _authSubscription;
  _LearningSyncBatch? _pendingBatch;
  bool _isDraining = false;
  int _nextSubscriberId = 0;

  Stream<LearningDomainEvent> get events => _events.stream;
  String get identityKey => _identityKey.value;
  Map<String, String> get lastFailures => Map.unmodifiable(_lastFailures);

  LearningSyncRegistration registerRefresher({
    required String owner,
    required Set<LearningDomain> domains,
    required LearningDomainRefresher refresh,
  }) {
    final id = ++_nextSubscriberId;
    _subscribers[id] = _LearningSyncSubscriber(
      owner: owner,
      domains: Set.unmodifiable(domains),
      refresh: refresh,
    );
    return LearningSyncRegistration(() => _subscribers.remove(id));
  }

  Future<LearningSyncReport> syncAfterCompletion(
    LearningResult result,
    LearningActivitySubmission submission,
  ) {
    return invalidate(LearningDomainEvent.afterCompletion(result, submission));
  }

  Future<LearningSyncReport> syncAfterLexiconChange({String? unitId}) {
    return invalidate(
      LearningDomainEvent(
        type: LearningDomainEventType.lexiconReviewed,
        domains: const <LearningDomain>{
          LearningDomain.journey,
          LearningDomain.unitPath,
          LearningDomain.stats,
          LearningDomain.mastery,
          LearningDomain.review,
          LearningDomain.profile,
          LearningDomain.session,
        },
        unitId: unitId,
        identityKey: identityKey,
      ),
    );
  }

  Future<LearningSyncReport> syncOnAppResume() {
    return invalidate(
      LearningDomainEvent(
        type: LearningDomainEventType.appResumed,
        domains: LearningDomain.values.toSet()..remove(LearningDomain.identity),
        identityKey: identityKey,
      ),
    );
  }

  Future<LearningSyncReport> invalidate(LearningDomainEvent event) {
    final completer = Completer<LearningSyncReport>();
    final pending = _pendingBatch;
    if (pending == null) {
      _pendingBatch = _LearningSyncBatch(event, [completer]);
    } else {
      pending.event = _mergeEvents(pending.event, event);
      pending.completers.add(completer);
    }
    if (!_isDraining) {
      _isDraining = true;
      scheduleMicrotask(_drain);
    }
    return completer.future;
  }

  Future<void> _drain() async {
    while (_pendingBatch != null) {
      final batch = _pendingBatch!;
      _pendingBatch = null;
      try {
        final report = await _dispatch(batch.event);
        for (final completer in batch.completers) {
          if (!completer.isCompleted) completer.complete(report);
        }
      } catch (error, stackTrace) {
        for (final completer in batch.completers) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      }
    }
    _isDraining = false;
  }

  LearningDomainEvent _mergeEvents(
    LearningDomainEvent current,
    LearningDomainEvent next,
  ) {
    final type = current.type == LearningDomainEventType.identityChanged ||
            next.type == LearningDomainEventType.identityChanged
        ? LearningDomainEventType.identityChanged
        : next.type == LearningDomainEventType.bossCompleted
            ? LearningDomainEventType.bossCompleted
            : next.type;
    return LearningDomainEvent(
      type: type,
      domains: <LearningDomain>{...current.domains, ...next.domains},
      unitId: next.unitId ?? current.unitId,
      levelId: next.levelId ?? current.levelId,
      identityKey: next.identityKey ?? current.identityKey,
      result: next.result ?? current.result,
      submission: next.submission ?? current.submission,
    );
  }

  Future<LearningSyncReport> _dispatch(LearningDomainEvent rawEvent) async {
    final event = rawEvent.withGeneration(generation.value + 1);
    generation.value = event.generation;
    isSyncing.value = true;
    _events.add(event);

    final refreshed = <String>{};
    final failures = <String, Object>{};
    final subscribers = _subscribers.values
        .where((subscriber) => subscriber.domains.any(event.domains.contains))
        .toList(growable: false);

    try {
      await Future.wait(
        subscribers.map((subscriber) async {
          Object? lastError;
          for (var attempt = 1; attempt <= maxRefreshAttempts; attempt++) {
            try {
              await subscriber.refresh(event);
              refreshed.add(subscriber.owner);
              return;
            } catch (error) {
              lastError = error;
            }
          }
          failures[subscriber.owner] = lastError!;
        }),
      );

      _lastFailures.assignAll(
        <String, String>{
          for (final entry in failures.entries) entry.key: '${entry.value}',
        },
      );
      return LearningSyncReport(
        event: event,
        refreshedOwners: Set.unmodifiable(refreshed),
        failures: Map.unmodifiable(failures),
      );
    } finally {
      isSyncing.value = false;
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _events.close();
    _subscribers.clear();
    super.onClose();
  }
}

class _LearningSyncSubscriber {
  const _LearningSyncSubscriber({
    required this.owner,
    required this.domains,
    required this.refresh,
  });

  final String owner;
  final Set<LearningDomain> domains;
  final LearningDomainRefresher refresh;
}

class _LearningSyncBatch {
  _LearningSyncBatch(this.event, this.completers);

  LearningDomainEvent event;
  final List<Completer<LearningSyncReport>> completers;
}
