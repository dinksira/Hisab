import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';

/// Renders the official multi-colour Google "G" mark.
class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    void arc(double fromDegrees, double toDegrees, Color color) {
      paint.color = color;
      canvas.drawArc(
        rect,
        fromDegrees * math.pi / 180,
        (toDegrees - fromDegrees) * math.pi / 180,
        false,
        paint,
      );
    }

    arc(135, 315, _blue);
    arc(315, 360, _red);
    arc(0, 60, _green);
    arc(60, 135, _yellow);

    // The horizontal bar that turns the ring into a "G".
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx + radius * 0.52,
        center.dy - strokeWidth / 2,
        center.dx + radius + strokeWidth / 2,
        center.dy + strokeWidth / 2,
      ),
      Paint()..color = _red,
    );
  }

  @override
  bool shouldRepaint(covariant GoogleLogoPainter oldDelegate) => false;
}

/// A sign-in button that follows the Google brand guidelines.
///
/// The button deliberately keeps its white background in dark mode because
/// the brand specification requires it.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF9AA0A6),
          side: const BorderSide(color: Color(0xFFDADCE0)),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3C4043),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CustomPaint(painter: GoogleLogoPainter()),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3C4043),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
