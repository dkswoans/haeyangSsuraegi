import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/photo_record.dart';

class PhotoState {
  final List<PhotoRecord> items;

  const PhotoState({required this.items});

  PhotoState copyWith({List<PhotoRecord>? items}) {
    return PhotoState(items: items ?? this.items);
  }
}

class PhotoController extends StateNotifier<PhotoState> {
  PhotoController() : super(const PhotoState(items: [])) {
    _seedDummy();
  }

  void _seedDummy() {
    final now = DateTime.now();
    state = PhotoState(
      items: [
        PhotoRecord(
          id: 1,
          imageUrl: 'assets/placeholder.png',
          cellRow: 1,
          cellCol: 3,
          createdAt: now.subtract(const Duration(minutes: 3)),
        ),
        PhotoRecord(
          id: 2,
          imageUrl: 'assets/placeholder.png',
          cellRow: 4,
          cellCol: 10,
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
        PhotoRecord(
          id: 3,
          imageUrl: 'assets/placeholder.png',
          cellRow: 2,
          cellCol: 6,
          createdAt: now.subtract(const Duration(minutes: 1)),
        ),
      ],
    );
  }

  PhotoRecord? latest() {
    if (state.items.isEmpty) return null;
    final sorted = [...state.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  void addDummy() {
    final random = Random();
    final nextId =
        (state.items.map((e) => e.id).fold<int>(0, (p, c) => c > p ? c : p)) +
        1;
    final now = DateTime.now();
    final newItem = PhotoRecord(
      id: nextId,
      imageUrl: 'assets/placeholder.png',
      cellRow: random.nextInt(6),
      cellCol: random.nextInt(18),
      createdAt: now,
    );
    state = state.copyWith(items: [newItem, ...state.items]);
  }
}

final photoControllerProvider =
    StateNotifierProvider<PhotoController, PhotoState>(
      (ref) => PhotoController(),
    );
