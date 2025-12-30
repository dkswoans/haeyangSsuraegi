import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _serverUrlKey = 'server_url';
  static const _startCmKey = 'start_cm';
  static const _endCmKey = 'end_cm';
  static const _laneCmKey = 'lane_cm';

  Future<String> loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? '';
  }

  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url.trim());
  }

  Future<Map<String, double>> loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'start': prefs.getDouble(_startCmKey) ?? 0,
      'end': prefs.getDouble(_endCmKey) ?? 60,
      'lane': prefs.getDouble(_laneCmKey) ?? 10,
    };
  }

  Future<void> saveCalibration({
    required double start,
    required double end,
    required double lane,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_startCmKey, start);
    await prefs.setDouble(_endCmKey, end);
    await prefs.setDouble(_laneCmKey, lane);
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});
