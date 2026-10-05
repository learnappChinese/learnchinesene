class UnitModel {
  final int id;
  final String title;
  final int order;

  const UnitModel({required this.id, required this.title, required this.order});

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: '${map['title'] ?? 'Bài học'}',
      order: (map['unit_order'] as num?)?.toInt() ?? 0,
    );
  }
}
