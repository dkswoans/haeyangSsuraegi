import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/photo.dart';
import '../../services/api_service.dart';
import '../../state/photo_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoControllerProvider);
    final items = state.items;
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final apiService = ref.read(apiServiceProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB91C1C),
                      ),
                ),
              ),
            Expanded(
              child: isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? const _EmptyState(label: 'No detections yet.')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final imageUrl = apiService.resolveImageUrl(
                              item.imageUrl,
                            );
                            return _HistoryCard(
                              item: item,
                              imageUrl: imageUrl,
                              timestamp:
                                  formatter.format(item.receivedAt.toLocal()),
                              onTap: () =>
                                  _showModal(context, item, imageUrl),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModal(BuildContext context, Photo item, String imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PhotoModal(item: item, imageUrl: imageUrl),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.imageUrl,
    required this.timestamp,
    required this.onTap,
  });

  final Photo item;
  final String imageUrl;
  final String timestamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedUrl = imageUrl;
    final isNetwork =
        resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://');

    String positionText() {
      final x = item.x;
      final y = item.y;
      if (x == null || y == null) {
        return 'Position unknown';
      }
      return 'x ${x.toStringAsFixed(1)}, y ${y.toStringAsFixed(1)}';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: _panelDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isNetwork
                    ? Image.network(
                        resolvedUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        resolvedUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID ${item.id}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      positionText(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF64748B),
        );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Color(0xFFCBD5F5),
          ),
          const SizedBox(height: 12),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

class _PhotoModal extends StatelessWidget {
  const _PhotoModal({required this.item, required this.imageUrl});
  final Photo item;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final theme = Theme.of(context);
    final resolvedUrl = imageUrl;
    final isNetwork =
        resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://');

    String positionLabel() {
      final x = item.x;
      final y = item.y;
      if (x == null || y == null) {
        return 'Unknown';
      }
      return '${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Photo detail',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isNetwork
                ? Image.network(
                    resolvedUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    resolvedUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailChip(label: 'ID', value: '#${item.id}'),
              _DetailChip(
                label: 'Position',
                value: positionLabel(),
              ),
              _DetailChip(
                label: 'Time',
                value: formatter.format(item.receivedAt.toLocal()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration([double radius = 16]) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  );
}
