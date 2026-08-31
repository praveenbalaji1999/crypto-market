import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceChangeBadge extends StatelessWidget {
  final double percent;
  final double fontSize;
  final bool compact;

  const PriceChangeBadge({
    super.key,
    required this.percent,
    this.fontSize = 12,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percent >= 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;
    final bgColor = isPositive
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.15);

    final text =
        '${isPositive ? '+' : ''}${percent.toStringAsFixed(2)}%';

    if (compact) {
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: fontSize + 4,
            color: color,
          ),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
