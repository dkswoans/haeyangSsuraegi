class PhotoRecord {
  final int id;
  final String imageUrl;
  final int cellRow;
  final int cellCol;
  final DateTime createdAt;

  const PhotoRecord({
    required this.id,
    required this.imageUrl,
    required this.cellRow,
    required this.cellCol,
    required this.createdAt,
  });

  factory PhotoRecord.fromJson(Map<String, dynamic> json) {
    return PhotoRecord(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      cellRow: json['cell_row'] as int? ?? 0,
      cellCol: json['cell_col'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
