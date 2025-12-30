import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/run_log_entry.dart';
import '../models/telemetry.dart';
import '../models/trash_item.dart';
import 'run_history_controller.dart';
import 'settings_controller.dart';

class TelemetryState {
  final Telemetry telemetry;
  final bool isConnected;
  final bool isSimulating;
  final List<TrashItem> trash;
  final String? targetTrashId;
  final List<Offset> pathPoints; // in cm
  final DateTime lastScan;

  const TelemetryState({
    required this.telemetry,
    required this.isConnected,
    required this.isSimulating,
    required this.trash,
    required this.targetTrashId,
    required this.pathPoints,
    required this.lastScan,
  });

  factory TelemetryState.initial() {
    return TelemetryState(
      telemetry: Telemetry(
        positionCm: 0,
        laneYCm: 10,
        speedLevel: 1,
        state: DeviceState.idle,
        trashEstimate: 0,
        headingDeg: 0,
      ),
      isConnected: false,
      isSimulating: false,
      trash: [],
      targetTrashId: null,
      pathPoints: [],
      lastScan: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  TelemetryState copyWith({
    Telemetry? telemetry,
    bool? isConnected,
    bool? isSimulating,
    List<TrashItem>? trash,
    String? targetTrashId,
    List<Offset>? pathPoints,
    DateTime? lastScan,
  }) {
    return TelemetryState(
      telemetry: telemetry ?? this.telemetry,
      isConnected: isConnected ?? this.isConnected,
      isSimulating: isSimulating ?? this.isSimulating,
      trash: trash ?? this.trash,
      targetTrashId: targetTrashId ?? this.targetTrashId,
      pathPoints: pathPoints ?? this.pathPoints,
      lastScan: lastScan ?? this.lastScan,
    );
  }
}

class TelemetryController extends StateNotifier<TelemetryState> {
  TelemetryController(this.ref) : super(TelemetryState.initial());

  final Ref ref;
  Timer? _timer;
  int _direction = 1; // +1 forward to 60, -1 back to 0
  DateTime? _runStart;

  void connectDemo() {
    state = state.copyWith(isConnected: true, lastScan: DateTime.now());
    refreshTrash();
  }

  void start({bool reverse = false}) {
    final settings = ref.read(settingsControllerProvider);
    final lane = settings.laneCm;
    final heading = reverse ? 180.0 : 0.0;
    state = state.copyWith(
      telemetry: state.telemetry.copyWith(laneYCm: lane, headingDeg: heading),
      pathPoints: [Offset(state.telemetry.positionCm, lane)],
    );
    _direction = reverse ? -1 : 1;
    _runStart ??= DateTime.now();
    _timer?.cancel();
    state = state.copyWith(
      isSimulating: true,
      telemetry: state.telemetry.copyWith(state: DeviceState.run),
    );
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _tick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      isSimulating: false,
      telemetry: state.telemetry.copyWith(state: DeviceState.stop),
    );
    _finalizeRunLog();
  }

  void returnHome() {
    start(reverse: true);
  }

  void setSpeed(double level) {
    state = state.copyWith(
      telemetry: state.telemetry.copyWith(speedLevel: level),
    );
  }

  void setLane(double laneY) {
    final clamped = laneY.clamp(0, 20);
    state = state.copyWith(
      telemetry: state.telemetry.copyWith(laneYCm: clamped.toDouble()),
    );
  }

  void refreshTrash() {
    _generateTrash();
  }

  void _tick() {
    final settings = ref.read(settingsControllerProvider);
    final minX = settings.startCm;
    final maxX = settings.endCm;
    final t = state.telemetry;
    final step = max(0.5, t.speedLevel) * 0.6; // cm per tick
    var next = t.positionCm + _direction * step;
    bool hitEdge = false;
    if (next >= maxX) {
      next = maxX;
      hitEdge = true;
    } else if (next <= minX) {
      next = minX;
      hitEdge = true;
    }
    final updated = t.copyWith(
      positionCm: next,
      trashEstimate: (t.trashEstimate + 0.02).clamp(0, 999),
      headingDeg: _direction > 0 ? 0 : 180,
    );
    final updatedPath = [
      ...state.pathPoints,
      Offset(updated.positionCm, updated.laneYCm),
    ];
    final limitedPath = updatedPath.length > 80
        ? updatedPath.sublist(updatedPath.length - 80)
        : updatedPath;
    state = state.copyWith(telemetry: updated, pathPoints: limitedPath);
    if (hitEdge) {
      stop();
    }
  }

  void _generateTrash() {
    final random = Random();
    final items = List.generate(6, (i) {
      return TrashItem(
        id: 'trash_${i + 1}',
        xCm: double.parse((random.nextDouble() * 60).toStringAsFixed(1)),
        yCm: double.parse((random.nextDouble() * 20).toStringAsFixed(1)),
        type: i.isEven ? 'plastic' : 'foam',
        confidence: double.parse(
          (0.5 + random.nextDouble() * 0.5).toStringAsFixed(2),
        ),
      );
    });
    final target = items.isEmpty ? null : items.first.id;
    state = state.copyWith(
      trash: items,
      targetTrashId: target,
      lastScan: DateTime.now(),
    );
  }

  TrashItem? nearestTrash() {
    if (state.trash.isEmpty) return null;
    final t = state.telemetry;
    TrashItem? best;
    double bestDist = double.infinity;
    for (final item in state.trash) {
      final dx = item.xCm - t.positionCm;
      final dy = item.yCm - t.laneYCm;
      final d = sqrt(dx * dx + dy * dy);
      if (d < bestDist) {
        bestDist = d;
        best = item;
      }
    }
    return best;
  }

  void _finalizeRunLog() {
    final start = _runStart;
    if (start == null) return;
    final end = DateTime.now();
    final entry = RunLogEntry(
      startTime: start,
      endTime: end,
      distanceCm: state.telemetry.positionCm,
      trashEstimate: state.telemetry.trashEstimate,
    );
    ref.read(runHistoryProvider.notifier).addEntry(entry);
    _runStart = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final telemetryProvider =
    StateNotifierProvider<TelemetryController, TelemetryState>((ref) {
      final controller = TelemetryController(ref);
      controller.connectDemo();
      return controller;
    });
