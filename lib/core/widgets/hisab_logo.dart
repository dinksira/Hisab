import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Hisab geometric brand logo and symbol widget.
/// Renders the signature "H" financial balance emblem with crisp vector geometry.
class HisabLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  final bool isDark;

  const HisabLogo({
    super.key,
    this.size = 36.0,
    this.showText = true,
    this.color,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (isDark ? AppColors.mintAccent : AppColors.forestPrimary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _HisabMarkPainter(color: effectiveColor),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.3),
          Text(
            'Hisab',
            style: AppTypography.heading1.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              fontSize: size * 0.72,
            ),
          ),
        ],
      ],
    );
  }
}

class _HisabMarkPainter extends CustomPainter {
  final Color color;

  _HisabMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final strokeW = w * 0.22;
    final radius = Radius.circular(w * 0.1);

    // Left vertical bar of H (representing assets / solid pillar)
    final leftBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, strokeW, h),
      radius,
    );
    canvas.drawRRect(leftBar, paint);

    // Right vertical bar of H (representing future growth / pillar)
    final rightBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - strokeW, 0, strokeW, h),
      radius,
    );
    canvas.drawRRect(rightBar, paint);

    // Dynamic balance bridge in the middle
    final bridge = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeW * 0.7, (h - strokeW) / 2, w - (strokeW * 1.4), strokeW),
      radius,
    );
    canvas.drawRRect(bridge, paint);

    // Accent dot representing clarity / precision balance
    final dotPaint = Paint()
      ..color = AppColors.mintAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.2),
      w * 0.08,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HisabMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
