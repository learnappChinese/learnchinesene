class Topic {
  final int id;
  final String title;
  final int order;

  const Topic({required this.id, required this.title, required this.order});

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: '${map['title'] ?? 'Chủ đề'}',
      order: (map['topic_order'] as num?)?.toInt() ?? 0,
    );
  }
}
