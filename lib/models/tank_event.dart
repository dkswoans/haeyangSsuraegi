import 'dart:convert';

class TankEvent {
  final String id;
  final DateTime timestamp;
  final int row;
  final int col;
  final int cellId;
  final String imageUrl;
  final bool isAsset;

  const TankEvent({
    required this.id,
    required this.timestamp,
    required this.row,
    required this.col,
    required this.cellId,
    required this.imageUrl,
    this.isAsset = false,
  });

  factory TankEvent.fromJson(Map<String, dynamic> json) {
    final rawCell = json['cell_id'] ?? json['cellId'] ?? 0;
    final parsedCellId = rawCell is int
        ? rawCell
        : int.tryParse('$rawCell') ?? 0;
    final rawRow = json['row'] ?? json['r'] ?? json['cell_row'];
    final rawCol = json['col'] ?? json['c'] ?? json['cell_col'];
    final row = rawRow is int
        ? rawRow
        : int.tryParse('$rawRow') ?? parsedCellId ~/ 3;
    final col = rawCol is int
        ? rawCol
        : int.tryParse('$rawCol') ?? parsedCellId % 3;
    final timestampRaw =
        json['timestamp'] as String? ?? json['created_at'] as String? ?? '';
    final timestamp =
        DateTime.tryParse(timestampRaw)?.toLocal() ?? DateTime.now();

    return TankEvent(
      id: json['id'] as String? ?? _randomFallbackId(),
      timestamp: timestamp,
      row: row,
      col: col,
      cellId: parsedCellId != 0 ? parsedCellId : row * 3 + col,
      imageUrl:
          json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'row': row,
      'col': col,
      'cell_id': cellId,
      'image_url': imageUrl,
      'is_asset': isAsset,
    };
  }

  TankEvent copyWith({
    String? id,
    DateTime? timestamp,
    int? row,
    int? col,
    int? cellId,
    String? imageUrl,
    bool? isAsset,
  }) {
    return TankEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      row: row ?? this.row,
      col: col ?? this.col,
      cellId: cellId ?? this.cellId,
      imageUrl: imageUrl ?? this.imageUrl,
      isAsset: isAsset ?? this.isAsset,
    );
  }

  static String cellLabel(int cellId) {
    final row = cellId ~/ 3;
    final col = cellId % 3;
    final rowLabel = row == 0 ? 'A' : 'B';
    return '$rowLabel${col + 1}';
  }

  static String _randomFallbackId() {
    final now = DateTime.now().toIso8601String();
    return 'evt_fallback_${base64Url.encode(utf8.encode(now))}';
  }
}
