enum ReviewCategory {
  words,
  listening,
  speaking,
  hanzi,
}

class ReviewSummary {
  final int totalDue;
  final int wordsDue;
  final int listeningDue;
  final int speakingDue;
  final int hanziDue;

  const ReviewSummary({
    this.totalDue = 0,
    this.wordsDue = 0,
    this.listeningDue = 0,
    this.speakingDue = 0,
    this.hanziDue = 0,
  });
}

class ReviewItem {
  final String id;
  final ReviewCategory category;
  final String title;
  final String subtitle;
  final String translation;
  final int wrongCount;
  final double score; // 0..100
  final String? audioUrl;
  final bool isWeak;
  final dynamic rawData;

  const ReviewItem({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.translation,
    this.wrongCount = 0,
    this.score = 0.0,
    this.audioUrl,
    this.isWeak = false,
    this.rawData,
  });
}
