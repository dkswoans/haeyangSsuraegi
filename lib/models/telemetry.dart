enum DeviceState { idle, run, stop, error }

class Telemetry {
  final double positionCm; // 0~60
  final double laneYCm; // 0~20
  final double speedLevel;
  final DeviceState state;
  final double trashEstimate;
  final double headingDeg; // 0~360, 0 = +X

  const Telemetry({
    required this.positionCm,
    required this.laneYCm,
    required this.speedLevel,
    required this.state,
    required this.trashEstimate,
    required this.headingDeg,
  });

  Telemetry copyWith({
    double? positionCm,
    double? laneYCm,
    double? speedLevel,
    DeviceState? state,
    double? trashEstimate,
    double? headingDeg,
  }) {
    return Telemetry(
      positionCm: positionCm ?? this.positionCm,
      laneYCm: laneYCm ?? this.laneYCm,
      speedLevel: speedLevel ?? this.speedLevel,
      state: state ?? this.state,
      trashEstimate: trashEstimate ?? this.trashEstimate,
      headingDeg: headingDeg ?? this.headingDeg,
    );
  }
}
