import 'package:flutter/material.dart' hide Text;
import 'localized_text.dart';

class ResponsiveStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const ResponsiveStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 14 : 20,
        horizontal: isSmallScreen ? 6 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 18),
        border: Border.all(color: const Color(0xFFEAE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D3553).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: const Color(0xFF172B45),
                fontSize: isSmallScreen ? 24 : 32,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: const Color(0xFF777063),
                    fontSize: isSmallScreen ? 11 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
