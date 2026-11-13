import 'package:flutter/material.dart';

class BujjiBackgroundPainter extends CustomPainter {
  const BujjiBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF061426),
          Color(0xFF020B18),
          Color(0xFF06172A),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final points = <Offset>[];

    for (int i = 0; i < 58; i++) {
      final x =
          ((i * 137.5) % 1000) / 1000 * size.width;

      final y =
          ((i * 83.7 + 25) % 1000) / 1000 * size.height;

      points.add(Offset(x, y));
    }

    final blueLinePaint = Paint()
      ..color = const Color(0xFF25B8FF).withOpacity(0.22)
      ..strokeWidth = 0.85;

    final goldLinePaint = Paint()
      ..color = const Color(0xFFFFC857).withOpacity(0.24)
      ..strokeWidth = 0.8;

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;
        if (distance < 145) {
          canvas.drawLine(
            points[i],
            points[j],
            ((i + j) % 5 == 0) ? goldLinePaint : blueLinePaint,
          );
        }
      }
    }

    final blueGlow = Paint()
      ..color = const Color(0xFF25B8FF).withOpacity(0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final goldGlow = Paint()
      ..color = const Color(0xFFFFC857).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final blueDot = Paint()..color = const Color(0xFF25B8FF);
    final goldDot = Paint()..color = const Color(0xFFFFC857);

    for (int i = 0; i < points.length; i++) {
      final isGold = i % 5 == 0;
      final point = points[i];
      canvas.drawCircle(point, 4.2, isGold ? goldGlow : blueGlow);
      canvas.drawCircle(point, 1.55, isGold ? goldDot : blueDot);
    }
  }

  @override
  bool shouldRepaint(
    covariant BujjiBackgroundPainter oldDelegate,
  ) {
    return false;
  }
}
