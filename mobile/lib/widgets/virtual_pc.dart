import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Hình bộ PC ảo nhìn qua kính hông: linh kiện đã chọn sáng lên, quạt quay;
/// khe chưa chọn hiện khung mờ. Chạm vào một khe để chọn linh kiện cho khe đó.
class VirtualPc extends StatefulWidget {
  const VirtualPc({super.key, required this.selected, required this.onTapSlot});

  /// Các slug đã chọn: cpu, mainboard, ram, vga, ssd, psu, case, cooler.
  final Set<String> selected;
  final ValueChanged<String> onTapSlot;

  @override
  State<VirtualPc> createState() => _VirtualPcState();
}

class _VirtualPcState extends State<VirtualPc> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  bool _has(String slug) => widget.selected.contains(slug);

  @override
  Widget build(BuildContext context) {
    final caseOn = _has('case');
    return AspectRatio(
      aspectRatio: 1.15,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10141F), Color(0xFF05070D)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: caseOn ? AppTheme.primary : Colors.white24, width: caseOn ? 2.5 : 1.5),
          boxShadow: caseOn
              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 1)]
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            Positioned at(double l, double t, double pw, double ph, Widget child) =>
                Positioned(left: l * w, top: t * h, width: pw * w, height: ph * h, child: child);

            return Stack(
              children: [
                // Vỏ case: chạm vùng trống để chọn case.
                Positioned.fill(child: GestureDetector(onTap: () => widget.onTapSlot('case'))),
                // Nhãn mainboard đặt góc trên-trái (giữa bảng mạch là chỗ của CPU/SSD).
                at(0.05, 0.06, 0.66, 0.62,
                    _part('mainboard', 'Mainboard', Icons.developer_board,
                        child: _boardTraces(), labelAlignment: const Alignment(-0.85, -0.85))),
                at(0.28, 0.14, 0.17, 0.20, _part('cpu', 'CPU', Icons.memory)),
                // Tản nhiệt đè lên CPU: chỉ hiện quạt quay khi đã chọn.
                at(0.255, 0.10, 0.22, 0.28, _cooler()),
                at(0.53, 0.09, 0.035, 0.30, _part('ram', '', Icons.view_week, compact: true)),
                at(0.585, 0.09, 0.035, 0.30, _part('ram', '', Icons.view_week, compact: true)),
                at(0.15, 0.40, 0.24, 0.05, _part('ssd', 'SSD', Icons.storage, compact: true)),
                at(0.08, 0.49, 0.60, 0.13, _gpu()),
                at(0.05, 0.75, 0.50, 0.18, _part('psu', 'Nguồn', Icons.power)),
                // Quạt trước của case.
                for (final top in [0.08, 0.31, 0.54]) at(0.78, top, 0.17, 0.20, _caseFan(caseOn)),
                // Nhãn case + tiến độ.
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: GestureDetector(
                    onTap: () => widget.onTapSlot('case'),
                    child: Text(
                      caseOn ? '${widget.selected.length}/8 linh kiện' : '+ Chọn vỏ case  ·  ${widget.selected.length}/8',
                      style: TextStyle(color: caseOn ? Colors.white : Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Một linh kiện dạng khối: sáng (đã chọn) hoặc khung mờ (chưa chọn).
  Widget _part(String slug, String label, IconData icon,
      {bool compact = false, Widget? child, Alignment labelAlignment = Alignment.center}) {
    final on = _has(slug);
    return GestureDetector(
      onTap: () => widget.onTapSlot(slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: on
              ? const LinearGradient(colors: [Color(0xFF0B3D91), AppTheme.primary])
              : null,
          color: on ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(compact ? 3 : 8),
          border: Border.all(color: on ? Colors.lightBlueAccent : Colors.white24, width: on ? 1.5 : 1),
          boxShadow: on ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.6), blurRadius: 10)] : null,
        ),
        child: Stack(
          children: [
            if (on && child != null) Positioned.fill(child: child),
            if (!compact)
              Align(
                alignment: labelAlignment,
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(on ? icon : Icons.add, color: on ? Colors.white : Colors.white38, size: 18),
                        Text(label, style: TextStyle(color: on ? Colors.white : Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Đường mạch trang trí trên mainboard khi đã chọn.
  Widget _boardTraces() => CustomPaint(painter: _TracePainter());

  Widget _fan(double size) => RotationTransition(
        turns: _spin,
        child: CustomPaint(size: Size.square(size), painter: const _FanPainter(Colors.lightBlueAccent)),
      );

  Widget _cooler() {
    final on = _has('cooler');
    return GestureDetector(
      onTap: () => widget.onTapSlot('cooler'),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: on ? 1 : 0.0,
        child: LayoutBuilder(
          builder: (_, b) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.6),
              border: Border.all(color: Colors.lightBlueAccent, width: 1.5),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.7), blurRadius: 12)],
            ),
            child: Center(child: _fan(b.maxWidth * 0.7)),
          ),
        ),
      ),
    );
  }

  Widget _gpu() {
    final on = _has('vga');
    if (!on) return _part('vga', 'Card đồ hoạ', Icons.videogame_asset);
    return GestureDetector(
      onTap: () => widget.onTapSlot('vga'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.lightBlueAccent, width: 1.5),
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.6), blurRadius: 12)],
        ),
        child: LayoutBuilder(
          builder: (_, b) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (var i = 0; i < 3; i++) _fan(b.maxHeight * 0.85)],
          ),
        ),
      ),
    );
  }

  Widget _caseFan(bool on) => LayoutBuilder(
        builder: (_, b) => AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: on ? Colors.lightBlueAccent : Colors.white12, width: 1.5),
            boxShadow: on ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.5), blurRadius: 10)] : null,
          ),
          child: Center(child: on ? _fan(b.maxWidth * 0.75) : const SizedBox()),
        ),
      );
}

/// Cánh quạt: trục giữa + 7 cánh cong.
class _FanPainter extends CustomPainter {
  const _FanPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final blade = Paint()..color = color.withValues(alpha: 0.85);
    const count = 7;
    for (var i = 0; i < count; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 2 * math.pi / count);
      final path = Path()
        ..moveTo(0, -r * 0.22)
        ..quadraticBezierTo(r * 0.55, -r * 0.45, r * 0.32, -r * 0.95)
        ..quadraticBezierTo(r * 0.05, -r * 0.75, 0, -r * 0.22)
        ..close();
      canvas.drawPath(path, blade);
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.24, Paint()..color = const Color(0xFF10141F));
    canvas.drawCircle(c, r * 0.24, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _FanPainter oldDelegate) => oldDelegate.color != color;
}

class _TracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 5; i++) {
      final y = size.height * i / 6;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width * 0.2, y)
        ..lineTo(size.width * 0.28, y - 8)
        ..lineTo(size.width * 0.6, y - 8);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
