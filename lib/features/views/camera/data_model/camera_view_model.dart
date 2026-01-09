import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';
import 'package:go_router/go_router.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/features/views/dashboard/data_model/home_view_model.dart';

class CameraViewModel extends ChangeNotifier {
  // final Map<String, Player> players = {};
  // final Map<String, VideoController> videoControllers = {};
  // Add VLC controllers map
  final Map<String, VlcPlayerController> vlcControllers = {};
  final Map<String, String?> videoErrors = {};
  final Map<String, Timer?> connectionTimers = {};
  final Map<String, bool> isStreamPlaying = {};

  // Search bar state
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  // Pagination state
  final ScrollController scrollController = ScrollController();

  bool isSearchExpanded = false;

  // Maximum number of simultaneous video players
  static const int maxSimultaneousPlayers = 6;

  // Track active players
  final Set<String> activePlayers = {};

  // In camera_page.dart - Update the _navigateToFilter method:
  void navigateToFilter(BuildContext context, HomeViewModel model) async {
    final result = await context.push<Map<String, String?>>('/filter');

    if (result != null) {
      // Show loading
      if (context.mounted) {
        model.isLoading = true;
      }

      try {
        // Fetch filtered data using the filter parameters
        // ignore: use_build_context_synchronously
        await model.fetchFilteredCameraData(context, result);
        notifyListeners();
      } catch (e) {
        LogService.debug('${AppStrings.ksErrorFetchingData} $e');
      }

      if (context.mounted) {
        model.isLoading = false;
      }
    }
  }
}
