import 'package:flutter/material.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';

class VlcPlayerWidget extends StatefulWidget {
  final String cameraId;
  final String videoUrl;
  final VlcPlayerController controller;

  VlcPlayerWidget({
    required this.cameraId,
    required this.videoUrl,
    required this.controller,
  }) : super(key: ValueKey(cameraId));

  @override
  State<VlcPlayerWidget> createState() => _VlcPlayerWidgetState();
}

class _VlcPlayerWidgetState extends State<VlcPlayerWidget> {
  bool _isPlayerReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  void _setupPlayer() {
    // Listen to controller state changes
    widget.controller.addListener(_onPlayerStateChanged);

    // Start playback after a short delay to ensure view is created
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.controller.value.isInitialized) {
        try {
          widget.controller.play();
          setState(() {
            _isPlayerReady = true;
          });
        } catch (e) {
          print('Error starting playback: $e');
          setState(() {
            _hasError = true;
          });
        }
      }
    });
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;

    // Update state when player is ready
    if (widget.controller.value.isInitialized && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
    }

    // Handle errors
    if (widget.controller.value.hasError) {
      print('VLC Player Error: ${widget.controller.value.errorDescription}');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Stream unavailable',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Use Positioned.fill to cover entire area
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate aspect ratio based on container size
              final aspectRatio = constraints.maxWidth / constraints.maxHeight;

              return VlcPlayer(
                controller: widget.controller,
                aspectRatio: aspectRatio,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
          ),
        ),
        if (!_isPlayerReady)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
