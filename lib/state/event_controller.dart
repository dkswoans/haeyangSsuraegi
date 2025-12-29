import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/tank_event.dart';
import '../services/event_repository.dart';
import 'settings_controller.dart';

class EventState {
  final List<TankEvent> events;
  final bool isLoading;
  final bool isConnected;
  final DateTime? lastUpdated;
  final String? error;

  const EventState({
    required this.events,
    required this.isLoading,
    required this.isConnected,
    required this.lastUpdated,
    required this.error,
  });

  factory EventState.initial() {
    return const EventState(
      events: [],
      isLoading: false,
      isConnected: false,
      lastUpdated: null,
      error: null,
    );
  }

  EventState copyWith({
    List<TankEvent>? events,
    bool? isLoading,
    bool? isConnected,
    DateTime? lastUpdated,
    String? error,
  }) {
    return EventState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
    );
  }
}

class EventController extends StateNotifier<EventState> {
  EventController(this.ref, this._repository) : super(EventState.initial()) {
    _seedDemoEvents();
    _setupSettingsListener();
  }

  final Ref ref;
  final EventRepository _repository;
  Timer? _poller;
  bool _refreshInFlight = false;

  void _setupSettingsListener() {
    ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
      if (previous?.serverUrl != next.serverUrl) {
        onServerUrlChanged(next.serverUrl);
      }
    });
  }

  Future<void> onServerUrlChanged(String url) async {
    _stopPolling();
    if (url.trim().isEmpty) {
      state = state.copyWith(isConnected: false);
      return;
    }
    await refreshEvents(useSince: false);
    _startPolling();
  }

  Future<void> refreshEvents({bool useSince = false}) async {
    if (_refreshInFlight) return;
    final baseUrl = ref.read(settingsControllerProvider).serverUrl.trim();
    if (baseUrl.isEmpty) {
      state = state.copyWith(isConnected: false, isLoading: false);
      return;
    }

    _refreshInFlight = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final since = useSince && state.events.isNotEmpty
          ? state.events.first.timestamp
          : null;
      final fetched = await _repository.fetchEvents(
        baseUrl: baseUrl,
        since: since,
      );
      final merged = _mergeEvents(fetched);
      state = state.copyWith(
        events: merged,
        isLoading: false,
        isConnected: true,
        lastUpdated: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isConnected: false,
        error: e.toString(),
      );
    } finally {
      _refreshInFlight = false;
    }
  }

  void simulateEvent() {
    final random = Random();
    final cellId = random.nextInt(6);
    final now = DateTime.now();
    final simulated = TankEvent(
      id: 'sim_${const Uuid().v4().split('-').first}',
      timestamp: now,
      row: cellId ~/ 3,
      col: cellId % 3,
      cellId: cellId,
      imageUrl: 'assets/placeholder.png',
      isAsset: true,
    );

    final merged = _mergeEvents([simulated]);
    state = state.copyWith(events: merged, lastUpdated: now, error: null);
  }

  void _seedDemoEvents() {
    final now = DateTime.now();
    final demoEvents = <TankEvent>[
      TankEvent(
        id: 'evt_1001',
        timestamp: now.subtract(const Duration(minutes: 5)),
        row: 0,
        col: 0,
        cellId: 0,
        imageUrl: 'assets/placeholder.png',
        isAsset: true,
      ),
      TankEvent(
        id: 'evt_1002',
        timestamp: now.subtract(const Duration(minutes: 3, seconds: 10)),
        row: 1,
        col: 0,
        cellId: 3,
        imageUrl: 'assets/placeholder.png',
        isAsset: true,
      ),
    ];

    state = state.copyWith(events: _mergeEvents(demoEvents));
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) {
      refreshEvents(useSince: true);
    });
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  List<TankEvent> _mergeEvents(List<TankEvent> incoming) {
    final map = <String, TankEvent>{
      for (final event in state.events) event.id: event,
    };
    for (final event in incoming) {
      map[event.id] = event;
    }
    final merged = map.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

final eventControllerProvider =
    StateNotifierProvider<EventController, EventState>((ref) {
      final repository = ref.read(eventRepositoryProvider);
      final controller = EventController(ref, repository);
      ref.onDispose(controller.dispose);
      return controller;
    });
