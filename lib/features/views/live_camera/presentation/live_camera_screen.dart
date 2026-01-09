import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';
import 'package:streaming_dashboard/core/config/toast_service/toast_service.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/core/theme/app_themes.dart';
import 'package:streaming_dashboard/features/views/dashboard/presentation/home_view.dart';
import 'package:streaming_dashboard/features/views/live_camera/presentation/play_back.dart';
import '../../dashboard/model/camera_live_model.dart';
import '../view_model/video_view_model.dart';
import '../widgets/video_player_widget.dart';
import './fullscreen_video_screen.dart';

class LiveCameraScreen extends StatefulWidget {
  final CameraData? cameraData;

  const LiveCameraScreen({super.key, this.cameraData});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  late CameraViewModel _viewModel;
  String? videoUrl;
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _viewModel = CameraViewModel();

    // Initialize the ViewModel's VLC player
    videoUrl = _getVideoUrl(widget.cameraData);
    final bool isRtsp = _isUsingRTSP(widget.cameraData);
    print('Video URL: $videoUrl, isRtsp: $isRtsp');
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      if (isRtsp) {
        // For RTSP, enable quality switching
        _viewModel.initializePlayer(videoUrl);
      } else {
        // For RTMP, play original URL without quality switching
        _viewModel.initializePlayerWithoutQuality(videoUrl);
      }
    }

    _viewModel.addListener(_onViewModelChanged);
  }

  String? _getVideoUrl(CameraData? camera) {
    if (camera?.rtmpUrl != null && camera!.rtmpUrl!.isNotEmpty) {
      return camera.rtmpUrl;
    } else if (camera?.rtspUrl != null && camera!.rtspUrl!.isNotEmpty) {
      return camera.rtspUrl;
    }
    return null;
  }

  bool _isUsingRTSP(CameraData? camera) {
    return (camera?.rtmpUrl?.isEmpty ?? true) &&
        (camera?.rtspUrl?.isNotEmpty ?? false);
  }

  bool _hasVideoUrl(CameraData? camera) {
    return (camera?.rtmpUrl != null && camera!.rtmpUrl!.isNotEmpty) ||
        (camera?.rtspUrl != null && camera!.rtspUrl!.isNotEmpty);
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _enterFullscreen() async {
    // Ensure we don't try to re-enter fullscreen
    if (_viewModel.isInFullScreen) return;

    // Tell the view model we're moving the player to fullscreen; that
    // causes the inline VlcPlayer to be removed from the tree.
    _viewModel.setFullScreen(true);

    // Give one frame (small delay) so the inline player is removed/detached.
    await Future.delayed(const Duration(milliseconds: 50));

    // Now push the fullscreen screen which will create a VlcPlayer using the same controller.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(viewModel: _viewModel),
      ),
    );

    // Restore inline player after returning
    _viewModel.setFullScreen(false);

    // Restore orientation/UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  DeviceType _getDeviceType(BoxConstraints constraints) {
    if (constraints.maxWidth >= 1024) {
      return DeviceType.ipad;
    } else if (constraints.maxWidth >= 600) {
      return DeviceType.tablet;
    } else {
      return DeviceType.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF1A1A1A)
        : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final surfaceColor = isDarkMode ? const Color(0xFF3A3A3A) : Colors.white;
    final borderColor = isDarkMode
        ? const Color(0xFF3A3A3A)
        : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final deviceType = _getDeviceType(constraints);
            final isLargeScreen = deviceType == DeviceType.ipad;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircularIconButton(
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.pop(context),
                          backgroundColor: backgroundColor,
                          iconColor: textColor,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          AppStrings.ksLiveCamera,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppThemes.getTextColor(context),
                                fontSize: isLargeScreen ? 20 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        // Show RTSP badge if using RTSP
                        if (_isUsingRTSP(widget.cameraData))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Text(
                              'RTSP',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Quality selector - Only show for RTSP
                  if (_isUsingRTSP(widget.cameraData))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Scrollable quality buttons
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (
                                    int i = 0;
                                    i <
                                        _viewModel
                                            .camera
                                            .availableQualities
                                            .length;
                                    i++
                                  ) ...[
                                    QualityButton(
                                      quality: _viewModel
                                          .camera
                                          .availableQualities[i],
                                      isSelected:
                                          _viewModel.selectedQuality ==
                                          _viewModel
                                              .camera
                                              .availableQualities[i],
                                      onTap: () => _viewModel.changeQuality(
                                        _viewModel.camera.availableQualities[i],
                                      ),
                                    ),
                                    if (i <
                                        _viewModel
                                                .camera
                                                .availableQualities
                                                .length -
                                            1)
                                      const SizedBox(width: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),

                  SizedBox(height: _isUsingRTSP(widget.cameraData) ? 24 : 0),

                  // Playback/Live button - Only show for RTSP
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Playback/Live button - only for RTSP
                        // if (_isUsingRTSP(widget.cameraData))
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_viewModel.isPlaybackMode) {
                              // If in playback mode, switch back to live
                              await _viewModel.switchToLive();
                              if (mounted) {
                                ToastService.showSuccess(
                                  AppStrings.ksSwitchToliveStream,
                                );
                              }
                            } else {
                              // Show playback dialog to select time range
                              final result =
                                  await showDialog<Map<String, DateTime?>>(
                                    context: context,
                                    builder: (context) =>
                                        const PlaybackDialog(),
                                  );

                              if (result != null) {
                                final fromTime = result['from'];
                                final toTime = result['to'];

                                // Check if both times are non-null
                                if (fromTime == null || toTime == null) {
                                  if (mounted) {
                                    ToastService.showInfo(
                                      AppStrings.ksStartTimeEndTime,
                                    );
                                  }
                                  return;
                                }

                                // Validate time range
                                if (toTime.isBefore(fromTime)) {
                                  if (mounted) {
                                    ToastService.showInfo(
                                      AppStrings.ksEndTimeMustAfterStartTime,
                                    );
                                  }
                                  return;
                                }

                                // Check if time range is reasonable (not more than 24 hours)
                                final duration = toTime.difference(fromTime);
                                if (duration.inHours > 24) {
                                  if (mounted) {
                                    ToastService.showInfo(
                                      AppStrings.ksPlaybackDuration,
                                    );
                                  }
                                  return;
                                }
                                print('toast appear');
                                // Load playback video for the selected time range
                                // await _viewModel.loadPlayback(fromTime, toTime);
                                await _viewModel.fetchPlaybackVideoAPI(
                                  context,
                                  fromTime,
                                  toTime,
                                  videoUrl ?? '',
                                );
                                if (mounted) {
                                  ToastService.showInfo(
                                    'Playing recording from ${_formatTime(fromTime)} to ${_formatTime(toTime)}',
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(
                            _viewModel.isPlaybackMode
                                ? Icons.videocam
                                : Icons.history,
                            color: _viewModel.isPlaybackMode
                                ? Colors.white
                                : textColor,
                          ),
                          label: Text(
                            _viewModel.isPlaybackMode
                                ? AppStrings.ksSwitchToLive
                                : AppStrings.ksPlayback,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: _viewModel.isPlaybackMode
                                      ? Colors.white
                                      : textColor,
                                  fontSize: isLargeScreen ? 20 : 18,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _viewModel.isPlaybackMode
                                ? const Color(0xFF00A3FF)
                                : surfaceColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),

                        if (_isUsingRTSP(widget.cameraData))
                          const SizedBox(width: 12),

                        // Play/Pause button
                        // CircularIconButton(
                        //   icon: _viewModel.isPlaying
                        //       ? Icons.pause
                        //       : Icons.play_arrow,
                        //   backgroundColor: surfaceColor,
                        //   onPressed: () => _viewModel.togglePlayback(),
                        // ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Video player section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 8.0,
                            bottom: 8.0,
                          ),
                          child: _InlineLiveBadge(
                            isPlaybackMode: _viewModel.isPlaybackMode,
                          ),
                        ),
                        GestureDetector(
                          onTap: _enterFullscreen,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black,
                              border: Border.all(
                                color: borderColor,
                                width: 20.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Stack(
                                  children: [
                                    // Only build the inline VlcPlayer when NOT in fullscreen.
                                    // When we go fullscreen we set viewModel.isInFullScreen = true,
                                    // which causes this to be replaced by a placeholder so the controller
                                    // can be attached to the fullscreen VlcPlayer.
                                    // Inside LiveCameraScreen build method
                                    if (_viewModel.isInitialized && !_viewModel.isInFullScreen)
                                      VlcPlayer(
                                        // Use the hash of the controller as a key to force rebuild when instance changes
                                        key: ValueKey(_viewModel.vlcController.hashCode),
                                        controller: _viewModel.vlcController,
                                        aspectRatio: 16 / 9,
                                        placeholder: const Center(
                                          child: CircularProgressIndicator(color: Colors.white),
                                        ),
                                      )
                                    else
                                      Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Loading video...',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Loading indicator when changing quality
                                    if (_viewModel.isLoadingQuality)
                                      Container(
                                        color: Colors.black.withOpacity(0.7),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFF00A3FF)),
                                                strokeWidth: 3,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                AppStrings.ksSwitchingQuality,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Fullscreen button overlay (bottom-right)
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _enterFullscreen,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.fullscreen,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Camera info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CameraInfoCard(
                      division: widget.cameraData?.divisionName ?? 'N/A',
                      district: widget.cameraData?.districtName ?? 'N/A',
                      workId: widget.cameraData?.tenderNumber ?? 'N/A',
                      workStatus: widget.cameraData?.workStatus ?? 'N/A',
                      resolutionType: _viewModel.selectedQuality,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// rest of file unchanged...
class _InlineLiveBadge extends StatefulWidget {
  final bool isPlaybackMode;

  const _InlineLiveBadge({this.isPlaybackMode = false});

  @override
  State<_InlineLiveBadge> createState() => InlineLiveBadgeState();
}

class InlineLiveBadgeState extends State<_InlineLiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getResponsiveFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 12.0;
    } else if (screenWidth < 400) {
      return 14.0;
    } else if (screenWidth < 600) {
      return 16.0;
    } else if (screenWidth < 900) {
      return 20.0;
    } else {
      return 24.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = _getResponsiveFontSize(context);
    final dotSize = fontSize * 0.5;

    // Show different badge based on mode
    if (widget.isPlaybackMode) {
      // Playback mode badge (blue, no animation)
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.6,
          vertical: fontSize * 0.3,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF00A3FF).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(fontSize * 0.8),
          border: Border.all(color: const Color(0xFF00A3FF), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              color: const Color(0xFF00A3FF),
              size: fontSize * 0.8,
            ),
            SizedBox(width: dotSize * 0.5),
            Text(
              AppStrings.ksPlayback,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF00A3FF),
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Live mode badge (red, animated)
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: dotSize * 0.5),
              Text(
                AppStrings.ksLive,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.day.toString().padLeft(2, '0')}'
      '/${dateTime.month.toString().padLeft(2, '0')}'
      '/${dateTime.year} '
      '${dateTime.hour.toString().padLeft(2, '0')}'
      ':${dateTime.minute.toString().padLeft(2, '0')}';
}
