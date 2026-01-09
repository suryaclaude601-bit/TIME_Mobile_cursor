import 'package:flutter/material.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';

/// A reusable loading overlay widgets that listens to a ChangeNotifier
/// and displays a full-screen loading indicator when isLoading is true
class LoadingOverlay extends StatelessWidget {
  final ChangeNotifier listenable;
  final bool Function(dynamic) isLoadingGetter;
  final String? loadingText;
  final Color? overlayColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    required this.listenable,
    required this.isLoadingGetter,
    this.loadingText,
    this.overlayColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, child) {
        final isLoading = isLoadingGetter(listenable);

        return isLoading
            ? Container(
                color: overlayColor ?? Colors.black.withValues(alpha: .5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            indicatorColor ?? const Color(0xFF9A0F24),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.ksLoading,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}
