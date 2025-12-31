import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/photo.dart';
import '../services/api_service.dart';

class PhotoState {
  final List<Photo> items;
  final bool isLoading;
  final String? errorMessage;

  const PhotoState({
    required this.items,
    required this.isLoading,
    this.errorMessage,
  });

  PhotoState copyWith({
    List<Photo>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PhotoState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PhotoController extends StateNotifier<PhotoState> {
  PhotoController({required ApiService apiService})
    : _apiService = apiService,
      super(const PhotoState(items: [], isLoading: true)) {
    _init();
  }

  final ApiService _apiService;
  final Set<int> _knownIds = {};
  Timer? _pollingTimer;
  DateTime? _lastReceivedAt;
  bool _pollingInFlight = false;

  Future<void> _init() async {
    await _fetchInitial();
    _startPolling();
  }

  Future<void> _fetchInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _apiService.fetchPhotos();
      _applyInitial(items);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to connect to server.',
      );
    }
  }

  void _applyInitial(List<Photo> items) {
    _knownIds
      ..clear()
      ..addAll(items.map((item) => item.id));
    final sorted = _sortByLatest(items);
    _lastReceivedAt = sorted.isEmpty ? null : sorted.first.receivedAt;
    state = state.copyWith(items: sorted, isLoading: false, errorMessage: null);
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollForNew(),
    );
  }

  Future<void> _pollForNew() async {
    if (_pollingInFlight) return;
    _pollingInFlight = true;
    try {
      final after = _lastReceivedAt?.toUtc().toIso8601String();
      final items = await _apiService.fetchPhotos(after: after);
      _mergeNew(items);
      if (state.errorMessage != null) {
        state = state.copyWith(errorMessage: null);
      }
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to connect to server.');
    } finally {
      _pollingInFlight = false;
    }
  }

  void _mergeNew(List<Photo> items) {
    final fresh = <Photo>[];
    for (final item in items) {
      if (_knownIds.add(item.id)) {
        fresh.add(item);
      }
    }
    if (fresh.isEmpty) return;
    final merged = _sortByLatest([...fresh, ...state.items]);
    _lastReceivedAt = merged.first.receivedAt;
    state = state.copyWith(items: merged, errorMessage: null);
  }

  List<Photo> _sortByLatest(List<Photo> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final cmp = b.receivedAt.compareTo(a.receivedAt);
      if (cmp != 0) return cmp;
      return b.id.compareTo(a.id);
    });
    return sorted;
  }

  Photo? latest() => state.items.isEmpty ? null : state.items.first;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final photoControllerProvider =
    StateNotifierProvider<PhotoController, PhotoState>(
      (ref) => PhotoController(apiService: ref.read(apiServiceProvider)),
    );
