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
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

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
            ? const Center(child: Text('No events yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: _EventThumbnail(event: event),
                      title: Text(
                        'Cell ${TankEvent.cellLabel(event.cellId)} (R${event.row}C${event.col})',
                      ),
                      subtitle: Text(formatter.format(event.timestamp)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(event: event),
                          ),
                        );
                      },
                    ),
                  );
                },
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
    final radius = BorderRadius.circular(10);
    if (event.isAsset) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          event.imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: event.imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(width: 56, height: 56, color: const Color(0xFFE2E8F0)),
        errorWidget: (_, __, ___) => Container(
          width: 56,
          height: 56,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }
}
