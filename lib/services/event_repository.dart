import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/tank_event.dart';

class EventRepository {
  EventRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<TankEvent>> fetchEvents({
    required String baseUrl,
    int limit = 100,
    DateTime? since,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('Server URL is not configured.');
    }

    final normalizedBase = _normalizeBaseUrl(baseUrl);
    final query = <String, String>{
      'limit': '$limit',
      if (since != null) 'since': since.toIso8601String(),
    };

    final uri = Uri.parse(
      '$normalizedBase/records',
    ).replace(queryParameters: query);

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch events (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format from server.');
    }

    return decoded.map((e) {
      final parsed = TankEvent.fromJson(e as Map<String, dynamic>);
      return parsed.copyWith(
        imageUrl: _resolveImageUrl(normalizedBase, parsed.imageUrl),
      );
    }).toList();
  }

  String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String _resolveImageUrl(String base, String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '$base$path';
    }
    return '$base/$path';
  }

  void dispose() {
    _client.close();
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final repository = EventRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
