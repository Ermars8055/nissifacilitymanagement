import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeType { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeType type;

  const StatusBadge({
    Key? key,
    required this.text,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case BadgeType.success:
        backgroundColor = AppTheme.success.withValues(alpha: 0.1);
        textColor = AppTheme.success;
        break;
      case BadgeType.warning:
        backgroundColor = AppTheme.warning.withValues(alpha: 0.1);
        textColor = AppTheme.warning;
        break;
      case BadgeType.error:
        backgroundColor = AppTheme.error.withValues(alpha: 0.1);
        textColor = AppTheme.error;
        break;
      case BadgeType.info:
        backgroundColor = AppTheme.info.withValues(alpha: 0.1);
        textColor = AppTheme.info;
        break;
      case BadgeType.neutral:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
