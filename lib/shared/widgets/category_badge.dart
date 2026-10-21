import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';

class CategoryBadge extends StatelessWidget {
  final String iconKey;
  final String? colorHex;
  final double size;
  final double iconSize;

  const CategoryBadge({
    super.key,
    required this.iconKey,
    this.colorHex,
    this.size = 44.0,
    this.iconSize = 22.0,
  });

  static IconData getIcon(String key) {
    switch (key.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'directions_car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'bolt':
      case 'utilities':
        return Icons.bolt_rounded;
      case 'movie':
      case 'entertainment':
        return Icons.movie_creation_outlined;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'medical_services':
      case 'health':
        return Icons.medical_services_outlined;
      case 'school':
      case 'education':
        return Icons.school_outlined;
      case 'work':
      case 'salary':
        return Icons.payments_outlined;
      case 'trending_up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'card_giftcard':
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'flight':
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'shield':
      case 'savings':
        return Icons.shield_outlined;
      default:
        return Icons.category_rounded;
    }
  }

  Color _resolveColor(BuildContext context) {
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        final hex = colorHex!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.mintAccent
        : AppColors.forestPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _resolveColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? baseColor.withAlpha(35) : baseColor.withAlpha(25),
        borderRadius: AppRadii.radiusMd,
      ),
      child: Center(
        child: Icon(
          getIcon(iconKey),
          color: baseColor,
          size: iconSize,
        ),
      ),
    );
  }
}
