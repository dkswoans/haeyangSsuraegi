class RunLogEntry {
  final DateTime startTime;
  final DateTime endTime;
  final double distanceCm;
  final double trashEstimate;

  const RunLogEntry({
    required this.startTime,
    required this.endTime,
    required this.distanceCm,
    required this.trashEstimate,
  });

  Map<String, dynamic> toJson() => {
    'start': startTime.toIso8601String(),
    'end': endTime.toIso8601String(),
    'distance_cm': distanceCm,
    'trash_estimate': trashEstimate,
  };

  factory RunLogEntry.fromJson(Map<String, dynamic> json) {
    return RunLogEntry(
      startTime: DateTime.parse(json['start'] as String),
      endTime: DateTime.parse(json['end'] as String),
      distanceCm: (json['distance_cm'] as num).toDouble(),
      trashEstimate: (json['trash_estimate'] as num).toDouble(),
    );
  }
}
