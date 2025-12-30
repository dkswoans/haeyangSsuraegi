import 'dart:ui' show lerpDouble, Offset;
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final formatter = DateFormat('MM/dd HH:mm');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: AppBar(
          toolbarHeight: 72,
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE9F2FF), Color(0xFFDDE8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
          titleSpacing: 16,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '수조 쓰레기 모니터',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1633),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '수조 현황을 실시간으로 확인하세요',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5B6B84),
                ),
              ),
            ],
          ),
          actions: const [],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF5F7FB)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _MetricsRow(
                  total: photos.length,
                  latest: latest,
                  formatter: formatter,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _TankSection(
                    items: photos,
                    showGrid: showGrid,
                    onToggleGrid: () => setState(() => showGrid = !showGrid),
                    onSelect: (item) => _showPhotoModal(context, item),
                  ),
                ),
                const SizedBox(height: 20),

                _ActionRow(
                  onLatest: latest == null
                      ? null
                      : () => _showPhotoModal(context, latest),
                  onHistory: _openHistory,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  void _showPhotoModal(BuildContext context, PhotoRecord item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PhotoModal(item: item),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.total,
    required this.latest,
    required this.formatter,
  });

  final int total;
  final PhotoRecord? latest;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    final latestText = latest == null
        ? '데이터 없음'
        : formatter.format(latest!.createdAt.toLocal());
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: '감지 수',
            value: '$total',
            icon: Icons.blur_on_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            label: '최근 기록',
            value: latestText,
            icon: Icons.access_time,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle =
        theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)) ??
        const TextStyle(color: Color(0xFF64748B), fontSize: 12);
    final valueStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
        const TextStyle(fontWeight: FontWeight.w700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _panelDecoration(14).copyWith(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 2),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TankSection extends StatelessWidget {
  const _TankSection({
    required this.items,
    required this.showGrid,
    required this.onToggleGrid,
    required this.onSelect,
  });

  final List<PhotoRecord> items;
  final bool showGrid;
  final VoidCallback onToggleGrid;
  final ValueChanged<PhotoRecord> onSelect;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            children: [
              _TankCard(
                child: Center(
                  child: TankViewport(
                    child: _TankMap(
                      items: items,
                      showGrid: showGrid,
                      onSelect: onSelect,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: OutlinedButton(
                  onPressed: onToggleGrid,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(42, 42),
                    shape: const CircleBorder(),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Icon(
                    showGrid ? Icons.grid_on : Icons.grid_off,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TankCard extends StatelessWidget {
  const _TankCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(18).copyWith(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
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

class TankViewport extends StatelessWidget {
  const TankViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        var width = maxWidth;
        var height = width / 3;
        if (height > maxHeight) {
          height = maxHeight;
          width = height * 3;
        }
        return SizedBox(width: width, height: height, child: child);
      },
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
    final base = Paint()..color = const Color(0xFFF1F5F9);
    final border = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2
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
      textDirection: ui.TextDirection.ltr,
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
      const conf = 0.7;
      final radius = (lerpDouble(minSize, maxSize, conf) ?? minSize) / 2;
      final paint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.8)
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onLatest, required this.onHistory});

  final VoidCallback? onLatest;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onHistory,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: Color(0xFFD5DEEB)),
            ),
            icon: const Icon(Icons.history),
            label: const Text('기록 보기'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onLatest,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.photo_outlined),
            label: const Text('최근 사진'),
          ),
        ),
      ],
    );
  }
}

class _PhotoModal extends StatelessWidget {
  const _PhotoModal({required this.item});
  final PhotoRecord item;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final theme = Theme.of(context);

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
                '사진 상세',
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
            child: item.imageUrl.startsWith('http')
                ? Image.network(
                    item.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    item.imageUrl,
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
                label: '셀 위치',
                value: '${item.cellRow}, ${item.cellCol}',
              ),
              _DetailChip(
                label: '시간',
                value: formatter.format(item.createdAt.toLocal()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
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
    border: Border.all(color: const Color(0xFFDCE5F1)),
    boxShadow: const [
      BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 5)),
    ],
  );
}
