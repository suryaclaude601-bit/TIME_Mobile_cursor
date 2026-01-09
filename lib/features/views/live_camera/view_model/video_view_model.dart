import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/core/config/shared_preferences/shared_preference_service.dart';
import 'package:streaming_dashboard/core/constants/api_constants.dart';
import 'package:streaming_dashboard/core/constants/api_endpoints.dart';
import 'package:streaming_dashboard/core/config/toast_service/toast_service.dart';
import 'package:streaming_dashboard/features/views/live_camera/model/playback_model.dart';
import 'package:streaming_dashboard/services/api_service.dart';
import '../model/camera_model.dart';

class CameraViewModel extends ChangeNotifier {
  // VLC player controller
  late VlcPlayerController _vlcController;
  CameraModel _camera = CameraModel.dummy();

  String _selectedQuality = 'SD (480 p)';
  String _baseRtspUrl = ''; // Store the original base URL
  String playbackUrl = '';

  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoadingQuality = false; // Track quality change loading state
  bool _isPlaybackMode = false; // Track if in playback mode
  bool _supportsQualitySwitching =
  true; // Track if quality switching is supported

  // New: track whether the player has been moved to fullscreen (so inline player can be hidden)
  bool _isInFullScreen = false;

  VlcPlayerController get vlcController => _vlcController;
  CameraModel get camera => _camera;
  String get selectedQuality => _selectedQuality;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  bool get isLoadingQuality => _isLoadingQuality;
  bool get isPlaybackMode => _isPlaybackMode;
  bool get supportsQualitySwitching => _supportsQualitySwitching;

  // New public getter for fullscreen flag
  bool get isInFullScreen => _isInFullScreen;

  // New setter to toggle fullscreen state. UI listens to this to remove/add the inline VlcPlayer.
  void setFullScreen(bool value) {
    if (_isInFullScreen == value) return;
    _isInFullScreen = value;
    notifyListeners();
  }

  /// Initialize player with quality switching support (for RTSP)
  void initializePlayer(String? rtspUrl) {
    _supportsQualitySwitching = true;

    // Store the base RTSP URL
    _baseRtspUrl = rtspUrl ?? '';

    // Get initial URL for quality
    final initialUrl = _getUrlForQuality(_selectedQuality);
    LogService.debug('Initializing with URL: $initialUrl');

    _initializeVlcController(initialUrl);
  }

  /// Initialize player without quality switching (for RTMP or other protocols)
  void initializePlayerWithoutQuality(String? videoUrl) {
    _supportsQualitySwitching = false;
    _baseRtspUrl = videoUrl ?? '';

    LogService.debug('Initializing without quality switching. URL: $videoUrl');

    _initializeVlcController(videoUrl ?? '');
  }

  /// Common VLC controller initialization
  void _initializeVlcController(String url) {
    // Initialize VLC player controller
    _vlcController = VlcPlayerController.network(
      url,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(300),
          VlcAdvancedOptions.liveCaching(300),
          VlcAdvancedOptions.clockJitter(300),
        ]),
        http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
        rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
      ),
    );

    // Listen for VLC events
    _vlcController.addListener(() {
      // Update playing state
      final newPlayingState = _vlcController.value.isPlaying;
      if (_isPlaying != newPlayingState) {
        _isPlaying = newPlayingState;
        notifyListeners();
      }

      // Update initialized state
      if (!_isInitialized && _vlcController.value.isInitialized) {
        _isInitialized = true;
        notifyListeners();
      }
    });

    // Mark as initialized
    _isInitialized = true;
    _isPlaying = true;
    notifyListeners();
  }

  /// Get the modified URL based on quality selection
  String _getUrlForQuality(String quality) {
    if (_baseRtspUrl.isEmpty) return '';

    try {
      // Manual parsing to handle @ symbols in password
      final lastAtIndex = _baseRtspUrl.lastIndexOf('@');
      if (lastAtIndex == -1) {
        // No credentials in URL, just modify the path
        return _modifyUrlPath(_baseRtspUrl, quality);
      }

      // Split into: protocol+credentials and host+path
      final credentialsPart = _baseRtspUrl.substring(0, lastAtIndex);
      final hostAndPath = _baseRtspUrl.substring(lastAtIndex + 1);

      // Find the path separator
      final pathSeparatorIndex = hostAndPath.indexOf('/');
      if (pathSeparatorIndex == -1) {
        // No path in URL
        return _baseRtspUrl;
      }

      final hostPart = hostAndPath.substring(0, pathSeparatorIndex);
      String path = hostAndPath.substring(pathSeparatorIndex + 1);

      // Modify the path based on quality
      path = _modifyPathForQuality(path, quality);

      // Reconstruct the URL
      final newUrl = '$credentialsPart@$hostPart/$path';

      LogService.debug('Quality: $quality -> URL: $newUrl');
      return newUrl;
    } catch (e) {
      LogService.debug('Error parsing URL: $e');
      return _baseRtspUrl;
    }
  }

  /// Modify just the URL path
  String _modifyUrlPath(String url, String quality) {
    final lastSlashIndex = url.lastIndexOf('/');
    if (lastSlashIndex == -1) return url;

    final basePart = url.substring(0, lastSlashIndex + 1);
    final path = url.substring(lastSlashIndex + 1);

    final modifiedPath = _modifyPathForQuality(path, quality);
    return '$basePart$modifiedPath';
  }

  /// Modify the path part based on quality
  String _modifyPathForQuality(String path, String quality) {
    // Split filename and extension
    final lastDotIndex = path.lastIndexOf('.');
    String baseName = path;
    String extension = '';

    if (lastDotIndex != -1) {
      baseName = path.substring(0, lastDotIndex); // e.g., ch01
      extension = path.substring(lastDotIndex); // e.g., .264
    }

    // Remove any existing quality suffix
    baseName = baseName.replaceAll(RegExp(r'_(fourth|third)$'), '');

    // Determine the quality suffix
    String qualitySuffix = '';

    // Extract quality from format like "SD (480 p)", "HD (720 p)", "High (1080 p)"
    if (quality.contains('480')) {
      qualitySuffix = '_fourth';
    } else if (quality.contains('720')) {
      qualitySuffix = '_third';
    } else if (quality.contains('1080')) {
      qualitySuffix = ''; // No suffix for 1080p
    } else {
      qualitySuffix = '';
    }

    // Reconstruct the path
    return '$baseName$qualitySuffix$extension';
  }

  Future<void> togglePlayback() async {
    if (_isPlaying) {
      await _vlcController.pause();
    } else {
      await _vlcController.play();
    }
    // The listener will update _isPlaying
  }

  Future<void> changeQuality(String quality) async {
    // Don't allow quality change if not supported
    if (!_supportsQualitySwitching) {
      LogService.debug('Quality switching not supported for this stream');
      return;
    }

    if (_selectedQuality == quality) return;

    LogService.debug('Changing quality from $_selectedQuality to $quality');
    _selectedQuality = quality;
    _isLoadingQuality = true;
    notifyListeners();

    try {
      // Get the new URL for the selected quality
      final newUrl = _getUrlForQuality(quality);

      // Dispose old controller and create new one
      await _vlcController.dispose();

      _vlcController = VlcPlayerController.network(
        newUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(300),
            VlcAdvancedOptions.liveCaching(300),
            VlcAdvancedOptions.clockJitter(300),
          ]),
          http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
          rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
        ),
      );

      // Re-add listener
      _vlcController.addListener(() {
        final newPlayingState = _vlcController.value.isPlaying;
        if (_isPlaying != newPlayingState) {
          _isPlaying = newPlayingState;
          notifyListeners();
        }
      });

      LogService.debug(
        'Successfully changed to quality: $quality with URL: $newUrl',
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _isLoadingQuality = false;
      notifyListeners();
    } catch (e) {
      LogService.debug('Error changing quality: $e');
      _isLoadingQuality = false;
      notifyListeners();
    }
  }

  Future<void> loadCameraData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _camera = CameraModel.dummy();
    notifyListeners();
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  /// Extract channel number from RTSP URL
  int _extractChannelNumber(String url) {
    final match = RegExp(r'ch(\d+)', caseSensitive: false).firstMatch(url);
    if (match != null) {
      final channelStr = match.group(1);
      return int.tryParse(channelStr ?? '1') ?? 1;
    }
    return 1;
  }

  /// Get stream type based on quality
  int _getStreamType(String quality) {
    if (quality.contains('1080')) {
      return 0; // Main stream
    }
    return 1; // Substream
  }

  /// Build playback URL
  String _buildPlaybackUrl(DateTime startTime, DateTime endTime) {
    try {
      // Parse the base URL
      final lastAtIndex = _baseRtspUrl.lastIndexOf('@');
      if (lastAtIndex == -1) return _baseRtspUrl;

      final credentialsPart = _baseRtspUrl.substring(0, lastAtIndex);
      final hostAndPath = _baseRtspUrl.substring(lastAtIndex + 1);

      final pathSeparatorIndex = hostAndPath.indexOf('/');
      if (pathSeparatorIndex == -1) return _baseRtspUrl;

      final hostPart = hostAndPath.substring(0, pathSeparatorIndex);

      // Extract channel number
      final channelNumber = _extractChannelNumber(_baseRtspUrl);

      // Get stream type
      final streamType = _getStreamType(_selectedQuality);

      // Format timestamps
      final startStr = _formatTimestamp(startTime);
      final endStr = _formatTimestamp(endTime);

      // Build the playback URL
      final playbackUrl =
          '$credentialsPart@$hostPart/recording?ch=$channelNumber&stream=$streamType&start=$startStr&stop=$endStr';

      LogService.debug('Playback URL: $playbackUrl');
      return playbackUrl;
    } catch (e) {
      LogService.debug('Error building playback URL: $e');
      return _baseRtspUrl;
    }
  }

  /// Format DateTime to YYYYMMDDHHMMSS
  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.year}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Load playback video (only for RTSP with quality switching)
  Future<void> loadPlayback(DateTime startTime, DateTime endTime) async {
    if (!_supportsQualitySwitching) {
      LogService.debug('Playback not supported for this stream type');
      return;
    }

    LogService.debug('Loading playback from $startTime to $endTime');

    _isLoadingQuality = true;
    _isPlaybackMode = true;
    notifyListeners();

    try {
      // Build the playback URL
      final playbackUrl = _buildPlaybackUrl(startTime, endTime);

      // Dispose old controller
      await _vlcController.dispose();

      // Create new controller for playback
      _vlcController = VlcPlayerController.network(
        playbackUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(300),
            VlcAdvancedOptions.liveCaching(300),
            VlcAdvancedOptions.clockJitter(300),
          ]),
          http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
          rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
        ),
      );

      // Re-add listener
      _vlcController.addListener(() {
        final newPlayingState = _vlcController.value.isPlaying;
        if (_isPlaying != newPlayingState) {
          _isPlaying = newPlayingState;
          notifyListeners();
        }
      });

      LogService.debug('Successfully loaded playback:$playbackUrl');

      await Future.delayed(const Duration(milliseconds: 500));

      _isLoadingQuality = false;
      notifyListeners();
    } catch (e) {
      LogService.debug('Error loading playback: $e');
      _isLoadingQuality = false;
      _isPlaybackMode = false;
      notifyListeners();
    }
  }

  /// Switch back to live stream
  Future<void> switchToLive() async {
    if (!_isPlaybackMode) return;

    LogService.debug('Switching back to live stream');

    _isLoadingQuality = true;
    notifyListeners();

    try {
      // Get the live URL
      final liveUrl = _supportsQualitySwitching
          ? _getUrlForQuality(_selectedQuality)
          : _baseRtspUrl;

      // Dispose old controller
      await _vlcController.dispose();

      // Create new controller for live stream
      _vlcController = VlcPlayerController.network(
        liveUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(300),
            VlcAdvancedOptions.liveCaching(300),
            VlcAdvancedOptions.clockJitter(300),
          ]),
          http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
          rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
        ),
      );

      // Re-add listener
      _vlcController.addListener(() {
        final newPlayingState = _vlcController.value.isPlaying;
        if (_isPlaying != newPlayingState) {
          _isPlaying = newPlayingState;
          notifyListeners();
        }
      });

      _isPlaybackMode = false;

      await Future.delayed(const Duration(milliseconds: 500));

      _isLoadingQuality = false;
      notifyListeners();

      LogService.debug('Successfully switched to live stream');
    } catch (e) {
      LogService.debug('Error switching to live: $e');
      _isLoadingQuality = false;
      notifyListeners();
    }
  }

  // Convert DateTime to ISO 8601 format without milliseconds
  String _formatToISO8601(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dateTime);
  }

  // Fetch playback video URL and play it
  Future<void> fetchPlaybackVideoAPI(
      BuildContext context,
      DateTime startTime,
      DateTime endTime,
      String url,
      ) async
  {
    if (!context.mounted) return;

    _isLoadingQuality = true;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        if (context.mounted) context.go('/login');
        return;
      }
      ApiService.instance.setAccessToken(accessToken);

      final requestData = {
        "cameraId": url.split('/').last,
        "startTime": _formatToISO8601(startTime),
        "endTime": _formatToISO8601(endTime),
      };

      LogService.debug('Fetching playback video: ${jsonEncode(requestData)}');

      final apiResponse = await ApiService.instance.post(
        endpoint: '${ApiConstants.playbackUrl}${ApiEndpoints.getPlaybackAPI}',
        data: requestData,
        fromJson: (json) => PlaybackModel.fromJson(json),
      );

      if (!context.mounted) return;

      // Inside fetchPlaybackVideoAPI in video_view_model.dart
      if (apiResponse.data != null && apiResponse.data!.videoUrl != null) {
        final playbackVideoUrl = apiResponse.data!.videoUrl!;

        // 1. Set loading state
        _isLoadingQuality = true;
        notifyListeners();

        // 2. Dispose old controller
        await _vlcController.dispose();

        // 3. Create new controller (Use consistent options)
        _vlcController = VlcPlayerController.network(
          playbackVideoUrl,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(1000), // Higher caching for MP4
            ]),
            rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
          ),
        );

        // 4. Update states BEFORE notifying
        _isPlaybackMode = true;
        _isInitialized = true;

        // 5. Re-attach listeners
        _vlcController.addListener(() {
          if (_isPlaying != _vlcController.value.isPlaying) {
            _isPlaying = _vlcController.value.isPlaying;
            notifyListeners();
          }
        });

        _isLoadingQuality = false;
        notifyListeners(); // This triggers the UI rebuild with the NEW controller
      }else {
        _isLoadingQuality = false;
        notifyListeners();

        if (context.mounted) {
          ToastService.showError('Failed to fetch playback video');
        }
        /*LogService.debug('Failed to fetch playback video: ${apiResponse.message}');*/
      }
    } catch (e) {
      _isLoadingQuality = false;
      notifyListeners();

      if (context.mounted) {
        ToastService.showError('Error loading playback: ${e.toString()}');
      }
      LogService.debug('Error fetching playback video: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}'
        '/${dateTime.month.toString().padLeft(2, '0')}'
        '/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}'
        ':${dateTime.minute.toString().padLeft(2, '0')}';
  }
}