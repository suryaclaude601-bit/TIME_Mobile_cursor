import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import '../view_model/video_view_model.dart';

class VideoScreen extends StatefulWidget {
  final CameraViewModel viewModel;

  const VideoScreen({super.key, required this.viewModel});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with TickerProviderStateMixin {
  bool _showControls = true;
  late AnimationController _scaleVideoAnimationController;
  Animation<double> _scaleVideoAnimation = const AlwaysStoppedAnimation<double>(
    1.0,
  );
  double? _targetVideoScale;

  // Cache value for later usage at the end of a scale-gesture
  double _lastZoomGestureScale = 1.0;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();

    // IMPORTANT: Only add listener, DO NOT reinitialize the controller
    widget.viewModel.addListener(_onViewModelChanged);
    _forceLandscape();

    // Initialize scale animation controller
    _scaleVideoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 125),
      vsync: this,
    );

    // Auto-hide controls after 3 seconds
    _startControlsTimer();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _forcePortrait();
    _scaleVideoAnimationController.dispose();
    // IMPORTANT: DO NOT dispose the controller here - it's managed by the viewModel
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  Future<void> _forceLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _forcePortrait() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  // Set target scale for zoom animation
  void setTargetNativeScale(double newValue) {
    if (!newValue.isFinite) {
      return;
    }

    // Limit zoom scale between 1.0 and 3.0
    newValue = newValue.clamp(1.0, 3.0);

    _scaleVideoAnimation = Tween<double>(begin: _currentScale, end: newValue)
        .animate(
          CurvedAnimation(
            parent: _scaleVideoAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _scaleVideoAnimationController.forward(from: 0).then((_) {
      _currentScale = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final qualities = widget.viewModel.camera.availableQualities;

    return Scaffold(
      body: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _toggleControls,
          onScaleUpdate: (details) {
            // Update zoom during pinch gesture
            if (details.scale != 1.0) {
              final newScale = _currentScale * details.scale;
              setState(() {
                // Apply scale directly during gesture for smooth feedback
                _currentScale = newScale.clamp(1.0, 3.0);
              });
            }
          },
          onScaleEnd: (details) {
            // Animate to final scale after gesture ends
            setTargetNativeScale(_currentScale);
          },
          onDoubleTap: () {
            // Double tap to reset zoom
            if (_currentScale != 1.0) {
              setTargetNativeScale(1.0);
            }
          },
          child: Stack(
            children: [
              Container(color: Colors.black),

              // VLC Video Player with zoom capability - USE THE EXISTING CONTROLLER
              Center(
                child: ScaleTransition(
                  scale: _scaleVideoAnimation,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: VlcPlayer(
                      controller: widget.viewModel.vlcController,
                      aspectRatio: 16 / 9,
                      placeholder: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

              // Loading indicator when changing quality
              if (widget.viewModel.isLoadingQuality)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00A3FF),
                          ),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppStrings.ksSwitchingQuality,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Top bar with back button and live badge
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Show live or playback badge based on mode
                              widget.viewModel.isPlaybackMode
                                  ? _PlaybackBadge()
                                  : const LiveBadge(),
                              const Spacer(),
                              // Zoom indicator/reset button
                              if (_currentScale != 1.0)
                                GestureDetector(
                                  onTap: () {
                                    setTargetNativeScale(1.0);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_out_map,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Reset Zoom',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Bottom bar with controls
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 20,
                            left: 20,
                            right: 20,
                          ),
                          child: Row(
                            children: [
                              // Play/Pause button
                              GestureDetector(
                                onTap: () => widget.viewModel.togglePlayback(),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.viewModel.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Quality selector - Only show if quality switching is supported
                              if (widget.viewModel.supportsQualitySwitching)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (
                                        int i = 0;
                                        i < qualities.length;
                                        i++
                                      ) ...[
                                        _QualityChip(
                                          quality: qualities[i],
                                          isSelected:
                                              widget
                                                  .viewModel
                                                  .selectedQuality ==
                                              qualities[i],
                                          onTap: () => widget.viewModel
                                              .changeQuality(qualities[i]),
                                        ),
                                        if (i < qualities.length - 1)
                                          const SizedBox(width: 8),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add a PlaybackBadge widget for when in playback mode
class _PlaybackBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00A3FF).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00A3FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, color: Color(0xFF00A3FF), size: 14),
          const SizedBox(width: 6),
          Text(
            'PLAYBACK',
            style: TextStyle(
              color: const Color(0xFF00A3FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  final String quality;
  final bool isSelected;
  final VoidCallback onTap;

  const _QualityChip({
    required this.quality,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Extract just the resolution (e.g., "480 p" from "SD (480 p)")
    String displayText = quality;
    if (quality.contains('(')) {
      final match = RegExp(r'\((.*?)\)').firstMatch(quality);
      if (match != null) {
        displayText = match.group(1)!.trim();
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          displayText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
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
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
