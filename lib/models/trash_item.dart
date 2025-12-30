class TrashItem {
  final String id;
  final double xCm; // 0~60
  final double yCm; // 0~20
  final String? type;
  final double? confidence;
  final bool isTarget;

  const TrashItem({
    required this.id,
    required this.xCm,
    required this.yCm,
    this.type,
    this.confidence,
    this.isTarget = false,
  });

  TrashItem copyWith({
    String? id,
    double? xCm,
    double? yCm,
    String? type,
    double? confidence,
    bool? isTarget,
  }) {
    return TrashItem(
      id: id ?? this.id,
      xCm: xCm ?? this.xCm,
      yCm: yCm ?? this.yCm,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      isTarget: isTarget ?? this.isTarget,
    );
  }
}
