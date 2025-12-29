import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/tank_event.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final TankEvent event;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Scaffold(
      appBar: AppBar(title: const Text('Event Detail')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventImage(event: event),
              const SizedBox(height: 16),
              Text('Event ID', style: Theme.of(context).textTheme.labelMedium),
              Text(event.id, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('Timestamp', style: Theme.of(context).textTheme.labelMedium),
              Text(
                formatter.format(event.timestamp),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text('Location', style: Theme.of(context).textTheme.labelMedium),
              Text(
                'Row ${event.row}, Col ${event.col}  •  Cell ${TankEvent.cellLabel(event.cellId)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.event});

  final TankEvent event;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final placeholder = Container(
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: radius,
      ),
      child: const Center(child: CircularProgressIndicator()),
    );

    if (event.isAsset) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          event.imageUrl,
          height: 260,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: event.imageUrl,
        height: 260,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: const Color(0xFFE2E8F0),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
