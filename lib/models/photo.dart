class Photo {
  final int id;
  final String imageUrl;
  final DateTime receivedAt;
  final double? x;
  final double? y;

  const Photo({
    required this.id,
    required this.imageUrl,
    required this.receivedAt,
    required this.x,
    required this.y,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      receivedAt: DateTime.parse(json['received_at'] as String),
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
    );
  }
}
