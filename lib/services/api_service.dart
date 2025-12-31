import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/photo.dart';

class ApiService {
  const ApiService();

  static const String baseUrl = 'http://10.66.156.112:8000';

  Future<List<Photo>> fetchPhotos({String? after, int limit = 50}) async {
    final queryParameters = <String, String>{'limit': '$limit'};
    if (after != null && after.isNotEmpty) {
      queryParameters['after'] = after;
    }
    final uri = Uri.parse(
      '$baseUrl/photos',
    ).replace(queryParameters: queryParameters);
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch photos (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format.');
    }
    return decoded
        .map((item) => Photo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String resolveImageUrl(String imageUrlFromServer) {
    final trimmed = imageUrlFromServer.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return '$baseUrl/$trimmed';
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => const ApiService());
