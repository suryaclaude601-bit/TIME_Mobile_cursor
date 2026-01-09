import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';

class PlaybackDialog extends StatefulWidget {
  const PlaybackDialog({super.key});

  @override
  State<PlaybackDialog> createState() => _PlaybackDialogState();
}

class _PlaybackDialogState extends State<PlaybackDialog> {
  DateTime? _fromDateTime;
  DateTime? _toDateTime;
  String? _fromDTime;
  String? _toDTime;

  Future<void> _selectDateTime(BuildContext context, bool isFromTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF2A2A2A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF4CAF50),
                onPrimary: Colors.white,
                surface: Color(0xFF2A2A2A),
                onSurface: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                ),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: const Color(0xFF2A2A2A),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isFromTime) {
            _fromDateTime = selectedDateTime;
            print('_fromDateTime: $_fromDateTime');
          } else {
            _toDateTime = selectedDateTime;
            print('_toDateTime: $_toDateTime');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

    // Responsive values
    final dialogPadding = isTablet ? 32.0 : (screenWidth < 360 ? 16.0 : 20.0);
    final maxDialogWidth = isTablet ? 500.0 : screenWidth - 32;
    final headerFontSize = isTablet ? 24.0 : (screenWidth < 360 ? 18.0 : 20.0);
    final iconSize = isTablet ? 28.0 : 24.0;
    final buttonVerticalPadding = isTablet
        ? 16.0
        : (screenWidth < 360 ? 12.0 : 14.0);
    final buttonFontSize = isTablet ? 18.0 : (screenWidth < 360 ? 14.0 : 16.0);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 16,
        vertical: isTablet ? 40 : 24,
      ),
      child: Container(
        padding: EdgeInsets.all(dialogPadding),
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: screenHeight * (isTablet ? 0.7 : 0.8),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 10 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.history,
                      color: const Color(0xFF4CAF50),
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Text(
                      AppStrings.ksStartPlaybackTime,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: headerFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 32 : 24),

              // From Time Selector
              _DateTimeCard(
                label: AppStrings.ksFrom,
                icon: Icons.calendar_today,
                dateTime: _fromDateTime,
                onTap: () => _selectDateTime(context, true),
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 20 : 16),

              // Arrow indicator
              Icon(
                Icons.arrow_downward,
                color: const Color(0xFF4CAF50),
                size: iconSize,
              ),
              SizedBox(height: isTablet ? 20 : 16),

              // To Time Selector
              _DateTimeCard(
                label: AppStrings.ksTo,
                icon: Icons.event,
                dateTime: _toDateTime,
                onTap: () => _selectDateTime(context, false),
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 32 : 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: buttonVerticalPadding,
                        ),
                        side: const BorderSide(
                          color: Color(0xFF3A3A3A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.ksCancel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white70,
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _fromDateTime != null && _toDateTime != null
                          ? () {
                              if (_toDateTime!.isAfter(_fromDateTime!)) {
                                Navigator.pop(context, {
                                  'from': _fromDateTime,
                                  'to': _toDateTime,
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppStrings.ksEndTimeMustAfterStartTime,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        disabledBackgroundColor: const Color(0xFF3A3A3A),
                        padding: EdgeInsets.symmetric(
                          vertical: buttonVerticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.ksPlay,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? dateTime;
  final VoidCallback onTap;
  final bool isTablet;

  const _DateTimeCard({
    required this.label,
    required this.icon,
    required this.dateTime,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    final cardPadding = isTablet ? 20.0 : 18.0;
    final iconSize = isTablet ? 24.0 : 20.0;
    final labelFontSize = isTablet ? 16.0 : 14.0;
    final dateFontSize = isTablet ? 16.0 : 14.0;
    final timeFontSize = isTablet ? 16.0 : 14.0;
    final placeholderFontSize = isTablet ? 16.0 : 14.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dateTime != null
                ? const Color(0xFF4CAF50).withValues(alpha: .5)
                : const Color(0xFF3A3A3A),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: dateTime != null
                      ? const Color(0xFF4CAF50)
                      : Colors.white54,
                  size: iconSize,
                ),
                SizedBox(width: isTablet ? 10 : 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: dateTime != null ? Colors.white : Colors.white54,
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            if (dateTime != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(dateTime!),

                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white70,
                                fontSize: dateFontSize,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        SizedBox(height: isTablet ? 6 : 4),
                        Text(
                          timeFormat.format(dateTime!),

                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white70,
                                fontSize: timeFontSize,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isTablet ? 8 : 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check,
                      color: const Color(0xFF4CAF50),
                      size: isTablet ? 20 : 16,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                AppStrings.ksSelectDateTime,

                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: .5),
                  fontSize: placeholderFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
