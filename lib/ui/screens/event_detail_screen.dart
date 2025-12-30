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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Detail')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _EventImage(event: event),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _panelDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Event ID', value: event.id),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Timestamp',
                    value: formatter.format(event.timestamp),
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Location',
                    value:
                        'Row ${event.row}, Col ${event.col} | Cell ${TankEvent.cellLabel(event.cellId)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
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
