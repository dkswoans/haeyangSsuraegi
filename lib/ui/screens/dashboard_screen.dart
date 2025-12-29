import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tank_event.dart';
import '../../state/event_controller.dart';
import '../../state/settings_controller.dart';
import '../screens/event_detail_screen.dart';
import '../screens/event_log_screen.dart';
import '../screens/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventState = ref.watch(eventControllerProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final controller = ref.read(eventControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tank Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => controller.refreshEvents(useSince: false),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConnectionStatus(
                isConnected: eventState.isConnected,
                hasServer: settingsState.serverUrl.trim().isNotEmpty,
              ),
              if (eventState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(minHeight: 4),
                ),
              if (eventState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    eventState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tank Grid (2 x 3)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Events: ${eventState.events.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AspectRatio(
                          aspectRatio: 3 / 2,
                          child: _TankGrid(events: eventState.events),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              eventState.lastUpdated != null
                                  ? 'Updated ${_formatTime(eventState.lastUpdated!)}'
                                  : 'Demo mode active',
                              style: const TextStyle(color: Color(0xFF475569)),
                            ),
                            const _Legend(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Simulate Event'),
                      onPressed: controller.simulateEvent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('View Event Log'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EventLogScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TankGrid extends StatelessWidget {
  const _TankGrid({required this.events});

  final List<TankEvent> events;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final cellEvents =
            events.where((event) => event.cellId == index).toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final overflowCount = cellEvents.length > 6 ? cellEvents.length - 6 : 0;
        final visibleDots = cellEvents.take(6).toList();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: const Color(0xFFF8FAFC),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TankEvent.cellLabel(index),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'R${index ~/ 3}C${index % 3}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final event in visibleDots) _EventDot(event: event),
                      if (overflowCount > 0)
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+$overflowCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EventDot extends StatelessWidget {
  const _EventDot({required this.event});

  final TankEvent event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.isConnected, required this.hasServer});

  final bool isConnected;
  final bool hasServer;

  @override
  Widget build(BuildContext context) {
    final isDemo = !hasServer;
    final color = isConnected
        ? const Color(0xFF16A34A)
        : isDemo
        ? const Color(0xFF0EA5E9)
        : Colors.redAccent;
    final label = isConnected
        ? 'Connected to Server'
        : isDemo
        ? 'Demo Mode (offline)'
        : 'Disconnected';
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(
                  (color.a * 0.3 * 255).clamp(0, 255).round(),
                ),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Trash collected',
          style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
      ],
    );
  }
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}
