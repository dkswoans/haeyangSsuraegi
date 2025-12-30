import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/photo_record.dart';
import '../../state/photo_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoControllerProvider);
    final controller = ref.read(photoControllerProvider.notifier);
    final items = state.items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Add dummy',
            icon: const Icon(Icons.add),
            onPressed: controller.addDummy,
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No detections yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrl.startsWith('http')
                          ? Image.network(
                              item.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              item.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                    ),
                    title: Text('ID ${item.id}'),
                    subtitle: Text(
                      'Cell (${item.cellRow}, ${item.cellCol}) • ${item.createdAt.toLocal().toIso8601String()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _showModal(context, item),
                  ),
                );
              },
            ),
    );
  }

  void _showModal(BuildContext context, PhotoRecord item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PhotoModal(item: item),
    );
  }
}

class _PhotoModal extends StatelessWidget {
  const _PhotoModal({required this.item});
  final PhotoRecord item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Photo Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl.startsWith('http')
                ? Image.network(item.imageUrl, height: 200, fit: BoxFit.cover)
                : Image.asset(item.imageUrl, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text('ID: ${item.id}'),
          Text('Cell: (${item.cellRow}, ${item.cellCol})'),
          Text('Created: ${item.createdAt.toLocal()}'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
