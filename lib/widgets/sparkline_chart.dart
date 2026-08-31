import 'package:flutter/material.dart';

/// A compact sparkline drawn with [CustomPaint].
/// Suitable for coin-list rows where fl_chart would be overkill.
class SparklineChart extends StatelessWidget {
  final List<double> prices;
  final Color color;
  final double width;
  final double height;
  final double strokeWidth;
  final bool showGradient;

  const SparklineChart({
    super.key,
    required this.prices,
    required this.color,
    this.width = 70,
    this.height = 36,
    this.strokeWidth = 1.8,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) return SizedBox(width: width, height: height);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          prices: prices,
          color: color,
          strokeWidth: strokeWidth,
          showGradient: showGradient,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> prices;
  final Color color;
  final double strokeWidth;
  final bool showGradient;

  const _SparklinePainter({
    required this.prices,
    required this.color,
    required this.strokeWidth,
    required this.showGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final minVal = prices.reduce((a, b) => a < b ? a : b);
    final maxVal = prices.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();

    double toX(int index) =>
        index / (prices.length - 1) * size.width;

    double toY(double price) {
      if (range == 0) return size.height / 2;
      return size.height -
          ((price - minVal) / range) * size.height * 0.85 -
          size.height * 0.075;
    }

    final path = Path();
    path.moveTo(toX(0), toY(prices[0]));
    for (int i = 1; i < prices.length; i++) {
      // Use cubic bezier for smooth curve
      final x0 = toX(i - 1);
      final y0 = toY(prices[i - 1]);
      final x1 = toX(i);
      final y1 = toY(prices[i]);
      final cx = (x0 + x1) / 2;
      path.cubicTo(cx, y0, cx, y1, x1, y1);
    }

    if (showGradient) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      );

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader =
              gradient.createShader(Offset.zero & size)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.prices != prices || old.color != color;
}
