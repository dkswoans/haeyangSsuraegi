import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/tank_event.dart';
import '../../state/event_controller.dart';
import 'event_detail_screen.dart';

class EventLogScreen extends ConsumerWidget {
  const EventLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventControllerProvider);
    final controller = ref.read(eventControllerProvider.notifier);
    final events = [...state.events]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final formatter = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshEvents(useSince: false),
          ),
        ],
      ),
      body: SafeArea(
        child: events.isEmpty
            ? const _EmptyState(label: 'No events yet.')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _EventCard(
                    event: event,
                    timestamp: formatter.format(event.timestamp),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.timestamp,
    required this.onTap,
  });

  final TankEvent event;
  final String timestamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: _panelDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _EventThumbnail(event: event),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cell ${TankEvent.cellLabel(event.cellId)} '
                      '(R${event.row}C${event.col})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
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

class _EventThumbnail extends StatelessWidget {
  const _EventThumbnail({required this.event});

  final TankEvent event;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    if (event.isAsset) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          event.imageUrl,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: event.imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(width: 64, height: 64, color: const Color(0xFFE2E8F0)),
        errorWidget: (_, __, ___) => Container(
          width: 64,
          height: 64,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.broken_image),
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
            Icons.event_busy,
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
