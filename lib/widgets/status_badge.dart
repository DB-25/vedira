import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label; // Optional custom label
  final bool showIcon;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.showIcon = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final statusInfo = _getStatusInfo(status, isDarkMode);
    final displayLabel = label ?? statusInfo.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(statusInfo.icon, size: 14, color: statusInfo.iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            displayLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusInfo.textColor,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status, bool isDarkMode) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return _StatusInfo(
          label: 'Pending',
          icon: Icons.schedule,
          backgroundColor:
              isDarkMode ? const Color(0xFF424242) : const Color(0xFFF5F5F5),
          borderColor:
              isDarkMode ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
          iconColor:
              isDarkMode ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
          textColor:
              isDarkMode ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
        );

      case 'GENERATING':
        return _StatusInfo(
          label: 'Generating',
          icon: Icons.autorenew,
          backgroundColor:
              isDarkMode ? const Color(0xFF1A237E) : const Color(0xFFE3F2FD),
          borderColor:
              isDarkMode ? const Color(0xFF3F51B5) : const Color(0xFF2196F3),
          iconColor:
              isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
          textColor:
              isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
        );

      case 'COMPLETED':
        return _StatusInfo(
          label: 'Completed',
          icon: Icons.check_circle,
          backgroundColor:
              isDarkMode ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E8),
          borderColor:
              isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF4CAF50),
          iconColor:
              isDarkMode ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
          textColor:
              isDarkMode ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        );

      case 'FAILED':
        return _StatusInfo(
          label: 'Failed',
          icon: Icons.error,
          backgroundColor:
              isDarkMode ? const Color(0xFF5D4037) : const Color(0xFFFFEBEE),
          borderColor:
              isDarkMode ? const Color(0xFFF44336) : const Color(0xFFF44336),
          iconColor:
              isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFD32F2F),
          textColor:
              isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFD32F2F),
        );

      default:
        return _StatusInfo(
          label: status,
          icon: Icons.help_outline,
          backgroundColor:
              isDarkMode ? const Color(0xFF424242) : const Color(0xFFF5F5F5),
          borderColor:
              isDarkMode ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
          iconColor:
              isDarkMode ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
          textColor:
              isDarkMode ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  _StatusInfo({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}
