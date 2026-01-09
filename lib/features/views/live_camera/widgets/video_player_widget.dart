import 'package:flutter/material.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/core/theme/app_themes.dart';

class QualityButton extends StatelessWidget {
  final String quality;
  final bool isSelected;
  final VoidCallback onTap;

  const QualityButton({
    super.key,
    required this.quality,
    required this.isSelected,
    required this.onTap,
  });

  // Calculate responsive font size
  double _getResponsiveFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) return 10.0;
    if (screenWidth < 400) return 11.0;
    if (screenWidth < 600) return 12.0;
    if (screenWidth < 900) return 14.0;
    return 16.0;
  }

  // Calculate responsive padding
  EdgeInsetsGeometry _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    } else if (screenWidth < 400) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    } else if (screenWidth < 600) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    } else if (screenWidth < 900) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    } else {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 14);
    }
  }

  // Calculate border radius
  double _getBorderRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) return 15.0;
    if (screenWidth < 400) return 18.0;
    if (screenWidth < 600) return 22.0;
    if (screenWidth < 900) return 26.0;
    return 30.0;
  }

  // Calculate border width
  double _getBorderWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) return 1.0;
    return 1.5;
  }

  @override
  Widget build(BuildContext context) {
    // Extract just the resolution part (e.g., "1080p" from "High (1080p)")
    String displayText = quality;
    if (quality.contains('(')) {
      // Get text inside parentheses
      final match = RegExp(r'\((.*?)\)').firstMatch(quality);
      if (match != null) {
        displayText = match.group(1)!.trim();
      }
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: _getResponsivePadding(context),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(_getBorderRadius(context)),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00A3FF)
                : (isDarkMode ? Colors.white38 : Colors.grey.shade400),

            width: _getBorderWidth(context),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00A3FF).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            displayText,

            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppThemes.getTextColor(context),
              fontSize: _getResponsiveFontSize(context),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.circle, color: Colors.red, size: 8),
          SizedBox(width: 6),
          Text(
            AppStrings.ksLive,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CameraInfoCard extends StatelessWidget {
  final String division;
  final String district;
  final String workId;
  final String workStatus;
  final String resolutionType;

  const CameraInfoCard({
    super.key,
    required this.division,
    required this.district,
    required this.workId,
    required this.workStatus,
    required this.resolutionType,
  });

  // Calculate responsive font size
  double _getResponsiveFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 10.0;
    if (screenWidth < 400) return 12.0;
    if (screenWidth < 600) return 14.0;
    if (screenWidth < 900) return 16.0;
    return 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF3A3A3A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black45;
    final labelColor = isDarkMode ? Colors.white70 : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          _buildTableRow('Div:', division, labelColor, textColor, context),
          _buildTableRow('District:', district, labelColor, textColor, context),
          _buildTableRow('Work ID:', workId, labelColor, textColor, context),
          _buildTableRow(
            'Work Status:',
            workStatus,
            labelColor,
            textColor,
            context,
          ),
          _buildTableRow(
            'Resolution Type:',
            resolutionType,
            labelColor,
            textColor,
            context,
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
    BuildContext context,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, right: 50.0),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: labelColor,
              fontSize: _getResponsiveFontSize(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontSize: _getResponsiveFontSize(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDarkMode ? const Color(0xFF3A3A3A) : Colors.white;
    final defaultIconColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBgColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        color: iconColor ?? defaultIconColor,
        onPressed: onPressed,
      ),
    );
  }
}
