import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

class SettingsState {
  final String serverUrl;
  final bool isLoaded;
  final double startCm;
  final double endCm;
  final double laneCm;

  const SettingsState({
    required this.serverUrl,
    required this.isLoaded,
    required this.startCm,
    required this.endCm,
    required this.laneCm,
  });

  SettingsState copyWith({
    String? serverUrl,
    bool? isLoaded,
    double? startCm,
    double? endCm,
    double? laneCm,
  }) {
    return SettingsState(
      serverUrl: serverUrl ?? this.serverUrl,
      isLoaded: isLoaded ?? this.isLoaded,
      startCm: startCm ?? this.startCm,
      endCm: endCm ?? this.endCm,
      laneCm: laneCm ?? this.laneCm,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._service)
    : super(
        const SettingsState(
          serverUrl: '',
          isLoaded: false,
          startCm: 0,
          endCm: 60,
          laneCm: 10,
        ),
      ) {
    _load();
  }

  final SettingsService _service;

  Future<void> _load() async {
    final url = await _service.loadServerUrl();
    final calib = await _service.loadCalibration();
    state = state.copyWith(
      serverUrl: url,
      isLoaded: true,
      startCm: calib['start'] ?? 0,
      endCm: calib['end'] ?? 60,
      laneCm: calib['lane'] ?? 10,
    );
  }

  Future<void> updateServerUrl(String url) async {
    state = state.copyWith(serverUrl: url);
    await _service.saveServerUrl(url);
  }

  Future<void> updateCalibration({
    required double start,
    required double end,
    required double lane,
  }) async {
    state = state.copyWith(startCm: start, endCm: end, laneCm: lane);
    await _service.saveCalibration(start: start, end: end, lane: lane);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final service = ref.read(settingsServiceProvider);
      return SettingsController(service);
    });
