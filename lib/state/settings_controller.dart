import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

class SettingsState {
  final String serverUrl;
  final bool isLoaded;

  const SettingsState({required this.serverUrl, required this.isLoaded});

  SettingsState copyWith({String? serverUrl, bool? isLoaded}) {
    return SettingsState(
      serverUrl: serverUrl ?? this.serverUrl,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._service)
    : super(const SettingsState(serverUrl: '', isLoaded: false)) {
    _load();
  }

  final SettingsService _service;

  Future<void> _load() async {
    final url = await _service.loadServerUrl();
    state = state.copyWith(serverUrl: url, isLoaded: true);
  }

  Future<void> updateServerUrl(String url) async {
    state = state.copyWith(serverUrl: url);
    await _service.saveServerUrl(url);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final service = ref.read(settingsServiceProvider);
      return SettingsController(service);
    });
