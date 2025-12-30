import 'dart:ui' show lerpDouble, Offset;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/photo_record.dart';
import '../../state/photo_controller.dart';
import 'history_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool showGrid = true;

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(photoControllerProvider).items;
    final latest = ref.read(photoControllerProvider.notifier).latest();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.08),
          elevation: 0,
          titleSpacing: 12,
          title: const Text(
            'Marine Trash Monitor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: 'History',
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            IconButton(
              tooltip: showGrid ? 'Hide grid' : 'Show grid',
              icon: Icon(showGrid ? Icons.grid_off : Icons.grid_on),
              onPressed: () => setState(() => showGrid = !showGrid),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F1FA), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: _TankCard(
                    child: AspectRatio(
                      aspectRatio: 3 / 1,
                      child: _TankMap(
                        items: photos,
                        showGrid: showGrid,
                        onSelect: (item) => _showPhotoModal(context, item),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoBar(total: photos.length, latest: latest),
                const SizedBox(height: 12),
                _PrimaryButton(
                  label: 'Show Latest Photo',
                  onPressed: latest == null
                      ? null
                      : () => _showPhotoModal(context, latest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoModal(BuildContext context, PhotoRecord item) {
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

class _TankCard extends StatelessWidget {
  const _TankCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
      ),
    );
  }
}

class _TankMap extends StatelessWidget {
  const _TankMap({
    required this.items,
    required this.showGrid,
    required this.onSelect,
  });

  final List<PhotoRecord> items;
  final bool showGrid;
  final ValueChanged<PhotoRecord> onSelect;

  static const gridRows = 6;
  static const gridCols = 18;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _TankPainter(
          items: items,
          showGrid: showGrid,
          rows: gridRows,
          cols: gridCols,
        ),
        child: Stack(
          children: [
            for (final item in items)
              Positioned.fill(
                child: _TapRegion(
                  item: item,
                  rows: gridRows,
                  cols: gridCols,
                  onTap: () => onSelect(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  _TankPainter({
    required this.items,
    required this.showGrid,
    required this.rows,
    required this.cols,
  });

  final List<PhotoRecord> items;
  final bool showGrid;
  final int rows;
  final int cols;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final base = Paint()..color = const Color(0xFFEFF4FA);
    final border = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, base);
    if (showGrid) _drawGrid(canvas, size);
    _drawDots(canvas, size);
    canvas.drawRect(rect, border);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var r = 1; r < rows; r++) {
      final y = size.height * (r / rows);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var c = 1; c < cols; c++) {
      final x = size.width * (c / cols);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    final labelStyle = const TextStyle(color: Color(0xFF94A3B8), fontSize: 10);
    TextPainter tp(String text) => TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp('0,0').paint(canvas, const Offset(6, 4));
    final topRight = tp('$cols,0');
    topRight.paint(canvas, Offset(size.width - topRight.width - 6, 4));
    final bottomLeft = tp('0,$rows');
    bottomLeft.paint(canvas, Offset(6, size.height - bottomLeft.height - 4));
    final bottomRight = tp('$cols,$rows');
    bottomRight.paint(
      canvas,
      Offset(
        size.width - bottomRight.width - 6,
        size.height - bottomRight.height - 4,
      ),
    );
  }

  void _drawDots(Canvas canvas, Size size) {
    const minSize = 8.0;
    const maxSize = 16.0;
    for (final item in items) {
      final x = ((item.cellCol + 0.5) / cols) * size.width;
      final y = ((item.cellRow + 0.5) / rows) * size.height;
      final conf = 0.7;
      final radius = (lerpDouble(minSize, maxSize, conf) ?? minSize) / 2;
      final paint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      final outline = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
      canvas.drawCircle(Offset(x, y), radius, outline);
    }
  }

  @override
  bool shouldRepaint(covariant _TankPainter oldDelegate) {
    return items != oldDelegate.items || showGrid != oldDelegate.showGrid;
  }
}

class _TapRegion extends StatelessWidget {
  const _TapRegion({
    required this.item,
    required this.rows,
    required this.cols,
    required this.onTap,
  });

  final PhotoRecord item;
  final int rows;
  final int cols;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final x = ((item.cellCol + 0.5) / cols) * constraints.maxWidth;
        final y = ((item.cellRow + 0.5) / rows) * constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: x - 20,
              top: y - 20,
              width: 40,
              height: 40,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.total, required this.latest});

  final int total;
  final PhotoRecord? latest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _InfoChip(label: 'Detected', value: '$total'),
          const SizedBox(width: 8),
          _InfoChip(
            label: 'Latest',
            value: latest == null
                ? 'None'
                : '#${latest!.id} • ${latest!.createdAt.toLocal().toIso8601String().substring(11, 19)}',
          ),
          const Spacer(),
          _Legend(),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.2),
          ),
        ),
        const SizedBox(width: 6),
        const Text('Detection', style: TextStyle(color: Color(0xFF475569))),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
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
