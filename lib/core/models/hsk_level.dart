class HskLevel {
  final int id;
  final String title;
  final int order;

  const HskLevel({required this.id, required this.title, required this.order});

  factory HskLevel.fromMap(Map<String, dynamic> map) {
    return HskLevel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: '${map['title'] ?? 'HSK'}',
      order: (map['level_order'] as num?)?.toInt() ?? 0,
    );
  }
}
