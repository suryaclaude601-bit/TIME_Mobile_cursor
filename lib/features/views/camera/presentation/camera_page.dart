import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/core/config/shared_preferences/shared_preference_service.dart';
import 'package:streaming_dashboard/core/config/toast_service/toast_service.dart';
import 'package:streaming_dashboard/core/constants/app_asset_images.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/core/theme/app_themes.dart';
import 'package:streaming_dashboard/features/views/camera/data_model/camera_view_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/data_model/home_view_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/model/camera_live_model.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';
import 'package:streaming_dashboard/features/views/dashboard/widget/vlcplayer_widget.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late HomeViewModel _viewModel;
  late CameraViewModel _cameraViewModel;
  late ScrollController _scrollController;
  final Map<String, VlcPlayerController> _vlcControllers = {};
  final Map<String, bool> _volumeSet = {};

  // Track visible cameras to limit simultaneous streams
  final Set<String> _visibleCameras = {};
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _cameraViewModel = CameraViewModel();
    _scrollController = ScrollController();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Pause all players when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseAllPlayers();
    }
    // Resume visible players when app comes back
    else if (state == AppLifecycleState.resumed) {
      _resumeVisiblePlayers();
    }
  }

  void _pauseAllPlayers() {
    for (var controller in _vlcControllers.values) {
      try {
        if (controller.value.isPlaying) {
          controller.pause();
        }
      } catch (e) {
        LogService.debug('Error pausing player: $e');
      }
    }
  }

  void _resumeVisiblePlayers() {
    for (var cameraId in _visibleCameras) {
      final controller = _vlcControllers[cameraId];
      if (controller != null) {
        try {
          if (!controller.value.isPlaying) {
            controller.play();
          }
        } catch (e) {
          LogService.debug('Error resuming player: $e');
        }
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }

    // Clean up off-screen players to save resources
    // Schedule cleanup after the current frame
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _cleanupOffScreenPlayers();
      }
    });
  }

  void _cleanupOffScreenPlayers() {
    final controllersToRemove = <String>[];

    for (var cameraId in _cameraViewModel.vlcControllers.keys) {
      if (!_visibleCameras.contains(cameraId)) {
        controllersToRemove.add(cameraId);
      }
    }

    // Remove controllers that are no longer visible
    for (var cameraId in controllersToRemove) {
      _disposeController(cameraId);
    }
  }

  void _disposeController(String cameraId) {
    if (!mounted) return;

    try {
      final controller = _vlcControllers[cameraId];
      if (controller != null) {
        // Schedule disposal after current frame to avoid build conflicts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (controller.value.isPlaying) {
              controller.stop();
            }
            controller.dispose();
          } catch (e) {
            LogService.debug('Error disposing controller for $cameraId: $e');
          }
        });
      }
      _vlcControllers.remove(cameraId);
      _cameraViewModel.vlcControllers.remove(cameraId);
      _cameraViewModel.videoErrors.remove(cameraId);
      _cameraViewModel.isStreamPlaying.remove(cameraId);
      _visibleCameras.remove(cameraId);
    } catch (e) {
      LogService.debug('Error disposing controller for $cameraId: $e');
    }
  }

  Future<void> _loadMoreData() async {
    if (_viewModel.isLoadingMore || !_viewModel.hasMoreData) return;

    if (_cameraViewModel.searchController.text.isNotEmpty ||
        _viewModel.selectedFilter != null) {
      return;
    }

    await _viewModel.fetchCameraData('Camera', context, loadMore: true);
    if (mounted) setState(() {});
  }

  Future<void> loadData() async {
    setState(() {
      _viewModel.isLoading = true; // ✓ Explicitly set loading state
    });
    await _viewModel.fetchCameraData('Camera', context);
    if (mounted) {
      setState(() {
        _viewModel.isLoading = false; // ✓ Explicitly clear loading state
      });
    }
  }

  Future<void> _handleRefresh() async {
    try {
      _cameraViewModel.searchController.clear();

      // Dispose all players before refresh
      _disposeAllPlayers();

      if (_viewModel.isFilterApplied) {
        await _viewModel.clearFiltersAndReload(context);
      } else {
        _viewModel.currentPage = 1;
        _viewModel.hasMoreData = true;
        await _viewModel.fetchCameraData('Camera', context, loadMore: false);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      LogService.debug('Error refreshing data: $e');
      if (mounted) {
        ToastService.showError('Failed to refresh data');
      }
    }
  }

  void _disposeAllPlayers() {
    final controllerIds = _vlcControllers.keys.toList();
    for (var cameraId in controllerIds) {
      _disposeController(cameraId);
    }
    _visibleCameras.clear();
  }

  void _navigateToFilter() async {
    final result = await context.push('/filter');

    if (result != null && result is Map<String, String?>) {
      setState(() {
        _viewModel.isLoading = true;
      });

      try {
        await _viewModel.fetchFilteredCameraData(context, result);
      } catch (e) {
        LogService.debug('${AppStrings.ksErrorFetchingData}: $e');
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    _buildActionButtons(constraints),
                    _buildCameraGridView(constraints),
                  ],
                );
              },
            ),
            // Whole page loading overlay
            if (_viewModel.isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
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

  Widget _buildActionButtons(BoxConstraints constraints) {
    final deviceType = _getDeviceType(constraints);
    final isLargeScreen = deviceType == DeviceType.ipad;
    final buttonPadding = isLargeScreen ? 14.0 : 12.0;
    final iconSize = isLargeScreen ? 32.0 : 28.0;

    return SizedBox(
      height: 50,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: 4.0),
        child: Row(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: _navigateToFilter,
                  child: Container(
                    padding: EdgeInsets.all(isLargeScreen ? 6 : 4),
                    decoration: BoxDecoration(
                      color: _viewModel.isFilterApplied
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      filterImg,
                      width: iconSize,
                      height: iconSize,
                    ),
                  ),
                ),
                if (_viewModel.isFilterApplied)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppThemes.getBackgroundColor(context),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),

            if (_viewModel.isFilterApplied) ...[
              GestureDetector(
                onTap: () async {
                  await _viewModel.clearFiltersAndReload(context);
                  if (mounted) setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.all(isLargeScreen ? 6 : 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.clear, size: iconSize, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Expanded(
            //   child: SizedBox(
            //     height: 42,
            //     child: TextField(
            //       controller: _cameraViewModel.searchController,
            //       focusNode: _cameraViewModel.searchFocusNode,
            //       onChanged: (value) {
            //         setState(() {});
            //       },
            //       style: TextStyle(
            //         color: AppThemes.getTextColor(context),
            //         fontSize: 13,
            //       ),
            //       decoration: InputDecoration(
            //         isDense: true,
            //         hintText: AppStrings.ksSearchCameras,
            //         hintStyle: TextStyle(
            //           color: AppThemes.getTextColor(
            //             context,
            //           ).withValues(alpha: 0.5),
            //           fontSize: 13,
            //         ),
            //         prefixIcon: Icon(
            //           Icons.search,
            //           color: AppThemes.getTextColor(context),
            //           size: 18,
            //         ),
            //         suffixIcon:
            //             _cameraViewModel.searchController.text.isNotEmpty
            //             ? IconButton(
            //                 icon: Icon(
            //                   Icons.clear,
            //                   color: AppThemes.getTextColor(context),
            //                   size: 18,
            //                 ),
            //                 padding: EdgeInsets.zero,
            //                 constraints: const BoxConstraints(),
            //                 onPressed: () {
            //                   _cameraViewModel.searchController.clear();
            //                   setState(() {});
            //                   _cameraViewModel.searchFocusNode.unfocus();
            //                 },
            //               )
            //             : null,
            //         filled: true,
            //         fillColor: AppThemes.getSurfaceColor(context),
            //         border: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(8),
            //           borderSide: BorderSide(
            //             color: AppThemes.getTextColor(
            //               context,
            //             ).withValues(alpha: 0.2),
            //           ),
            //         ),
            //         enabledBorder: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(8),
            //           borderSide: BorderSide(
            //             color: AppThemes.getTextColor(
            //               context,
            //             ).withValues(alpha: 0.2),
            //           ),
            //         ),
            //         focusedBorder: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(8),
            //           borderSide: BorderSide(
            //             color: Theme.of(context).primaryColor,
            //             width: 1.5,
            //           ),
            //         ),
            //         contentPadding: const EdgeInsets.symmetric(
            //           horizontal: 12,
            //           vertical: 8,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraGridView(BoxConstraints constraints) {
    final deviceType = _getDeviceType(constraints);
    final padding = deviceType == DeviceType.ipad ? 24.0 : 16.0;
    if (_viewModel.isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: AppThemes.getTextColor(context),
          ),
        ),
      );
    }
    if (_viewModel.errorMessage != null) {
      return Expanded(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.white,
          backgroundColor: AppThemes.getSurfaceColor(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _viewModel.errorMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: Text(
                        AppStrings.ksRetry,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add null check before accessing cameraData
    if (_viewModel.cameraData == null ||
        _viewModel.cameraData!.data == null ||
        _viewModel.cameraData!.data!.isEmpty) {
      return Expanded(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.white,
          backgroundColor: AppThemes.getSurfaceColor(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Text(
                  AppStrings.ksCameraDataNotAvailable,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Now it's safe to use the ! operator
    List<CameraData> filteredCameras = _viewModel.cameraData!.data ?? [];

    if (_cameraViewModel.searchController.text.isNotEmpty) {
      final searchQuery = _cameraViewModel.searchController.text.toLowerCase();
      filteredCameras = filteredCameras.where((camera) {
        final districtNameMatch =
            camera.districtName?.toLowerCase().contains(searchQuery) ?? false;
        final districtIdMatch =
            camera.districtIds?.toString().toLowerCase().contains(
              searchQuery,
            ) ??
            false;
        final divisionNameMatch =
            camera.divisionName?.toLowerCase().contains(searchQuery) ?? false;
        final divisionIdMatch =
            camera.divisionIds?.toString().toLowerCase().contains(
              searchQuery,
            ) ??
            false;
        final workStatusMatch =
            camera.workStatus?.toLowerCase().contains(searchQuery) ?? false;
        final tenderNumberMatch =
            camera.tenderNumber?.toLowerCase().contains(searchQuery) ?? false;
        final tenderIdMatch =
            camera.tenderId?.toString().toLowerCase().contains(searchQuery) ??
            false;
        final channelMatch =
            camera.channel?.toLowerCase().contains(searchQuery) ?? false;
        final mainCategoryMatch =
            camera.mainCategory?.toLowerCase().contains(searchQuery) ?? false;
        final subcategoryMatch =
            camera.subcategory?.toLowerCase().contains(searchQuery) ?? false;

        return districtNameMatch ||
            districtIdMatch ||
            divisionNameMatch ||
            divisionIdMatch ||
            workStatusMatch ||
            tenderNumberMatch ||
            tenderIdMatch ||
            channelMatch ||
            mainCategoryMatch ||
            subcategoryMatch;
      }).toList();
    }

    if (_viewModel.selectedFilter != null &&
        _viewModel.selectedFilter != 'all') {
      if (_viewModel.selectedFilter == 'camera-alerts') {
        filteredCameras = filteredCameras
            .where(
              (camera) => camera.rtmpUrl == null || camera.rtmpUrl!.isEmpty,
            )
            .toList();
      } else {
        filteredCameras = filteredCameras
            .where(
              (camera) =>
                  camera.workStatus?.toLowerCase() ==
                  _viewModel.selectedFilter!.toLowerCase(),
            )
            .toList();
      }
    }

    if (filteredCameras.isEmpty && _viewModel.cameraData != null) {
      return Expanded(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.white,
          backgroundColor: AppThemes.getSurfaceColor(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_alt_off,
                      color: Colors.white.withValues(alpha: .5),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _cameraViewModel.searchController.text.isNotEmpty
                          ? '${AppStrings.ksNoCamerasFound} "${_cameraViewModel.searchController.text}"'
                          : '${AppStrings.ksNoCamerasFound} "${_viewModel.selectedFilter ?? AppStrings.ksAll}"',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.white,
        backgroundColor: AppThemes.getSurfaceColor(context),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount:
                (filteredCameras.length / 2).ceil() +
                (_viewModel.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == (filteredCameras.length / 2).ceil()) {
                return _buildLoadingIndicator();
              }
              final firstIndex = index * 2;
              final secondIndex = firstIndex + 1;
              final hasSecondItem = secondIndex < filteredCameras.length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCameraCard(
                        filteredCameras[firstIndex],
                        deviceType,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: hasSecondItem
                          ? _buildCameraCard(
                              filteredCameras[secondIndex],
                              deviceType,
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildCameraCard(CameraData camera, DeviceType deviceType) {
    final fontSize = deviceType == DeviceType.ipad ? 12.0 : 10.0;
    final cameraId = camera.rtmpUrl ?? camera.rtspUrl ?? '';

    return GestureDetector(
      onTap: () {
        /*if ((camera.rtmpUrl == null || camera.rtmpUrl!.isEmpty) ||
            (camera.rtspUrl == null || camera.rtspUrl!.isEmpty)) {
          ToastService.showError(AppStrings.ksVideoURLNotAvailable);
          return;
        }*/
        context.push('/live_camera', extra: camera);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppThemes.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppThemes.getTextColor(context).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                camera.tenderNumber ?? AppStrings.ksNA,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemes.getTextColor(context),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCameraStatusColor(
                    camera.workStatus,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getCameraStatusColor(camera.workStatus),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        camera.workStatus ?? AppStrings.ksUnknown,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _getCameraStatusColor(camera.workStatus),
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              height: 160,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemes.getTextColor(context).withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    (camera.rtmpUrl != null && camera.rtmpUrl!.isNotEmpty) ||
                        (camera.rtspUrl != null && camera.rtspUrl!.isNotEmpty)
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: _buildVideoPlayer(cameraId, camera),
                          ),

                          // Only show Live badge if stream is NOT in error state
                          if (_cameraViewModel.videoErrors[cameraId] == null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: _InlineLiveBadge(fontSize: fontSize + 1),
                              ),
                            ),

                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_off,
                              color: Colors.grey.shade600,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                AppStrings.ksVideoURLNotAvailable,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.grey.shade500,
                                      fontSize: fontSize,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Color _getCameraStatusColor(String? status) {
    return Colors.grey;
  }

  Widget _buildVideoPlayer(String cameraId, CameraData camera) {
    String? videoUrl;

    // Priority: RTMP first, then RTSP
    if (camera.rtmpUrl != null && camera.rtmpUrl!.isNotEmpty) {
      videoUrl = camera.rtmpUrl;
    } else if (camera.rtspUrl != null && camera.rtspUrl!.isNotEmpty) {
      videoUrl = camera.rtspUrl;
    }

    // Case 1: No video URL available - Show "Stream unavailable"
    if (videoUrl == null || videoUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              color: Colors.white.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Stream unavailable',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Check if video should be playing
    final shouldPlay = _viewModel.isVideoPlaying[cameraId] ?? false;

    // Case 2: Video URL available but not playing - Show thumbnail with play icon
    if (!shouldPlay) {
      return _buildThumbnailView(cameraId, camera);
    }

    // Case 3: Video is playing - Initialize controller and show video
    if (!_vlcControllers.containsKey(cameraId)) {
      try {
        final controller = VlcPlayerController.network(
          videoUrl,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
              VlcAdvancedOptions.liveCaching(2000),
              VlcAdvancedOptions.clockJitter(0),
            ]),
            http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
            rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
            extras: ['--no-audio', '--audio-track=-1'],
          ),
        );

        // Store controller first
        _vlcControllers[cameraId] = controller;

        // ✅ FIXED: Use a one-time listener with proper cleanup
        void volumeListener() {
          // Check if this controller still exists and matches
          if (_vlcControllers[cameraId] != controller) {
            // Controller was replaced, remove this listener
            try {
              controller.removeListener(volumeListener);
            } catch (e) {
              LogService.debug('Error removing old listener: $e');
            }
            return;
          }

          if (controller.value.isInitialized &&
              !(_volumeSet[cameraId] ?? false)) {
            try {
              controller.setVolume(0);
              _volumeSet[cameraId] = true;
              // Remove listener after setting volume once
              controller.removeListener(volumeListener);
            } catch (e) {
              LogService.debug('Error setting volume for $cameraId: $e');
            }
          }
        }

        controller.addListener(volumeListener);
      } catch (e) {
        LogService.debug('Error creating VLC controller for $cameraId: $e');
        return _buildThumbnailView(cameraId, camera);
      }
    }

    // Show video player
    return Stack(
      children: [
        Positioned.fill(
          child: VlcPlayerWidget(
            cameraId: cameraId,
            videoUrl: videoUrl,
            controller: _vlcControllers[cameraId]!,
          ),
        ),
        // Stop button overlay
        Positioned(
          top: 8,
          left: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _viewModel.toggleVideoPlayback(cameraId);
              });
              // Stop and dispose controller
              if (_vlcControllers.containsKey(cameraId)) {
                final controller = _vlcControllers[cameraId]!;
                try {
                  if (controller.value.isPlaying) {
                    controller.stop();
                  }
                  controller.dispose();
                } catch (e) {
                  LogService.debug('Error stopping controller: $e');
                }
                _vlcControllers.remove(cameraId);
                _volumeSet.remove(cameraId);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  // Add this new method to build thumbnail view
  Widget _buildThumbnailView(String cameraId, CameraData camera) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewModel.toggleVideoPlayback(cameraId);
        });
      },
      child: Stack(
        children: [
          // Background with gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                    Colors.grey.shade900,
                  ],
                ),
              ),
            ),
          ),

          // Camera icon and info
          // Positioned.fill(
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       // Camera icon with circle background
          //       Container(
          //         padding: const EdgeInsets.all(20),
          //         decoration: BoxDecoration(
          //           color: Colors.black.withValues(alpha: 0.3),
          //           shape: BoxShape.circle,
          //           border: Border.all(
          //             color: Colors.white.withValues(alpha: 0.2),
          //             width: 2,
          //           ),
          //         ),
          //         child: Icon(
          //           Icons.videocam,
          //           color: Colors.white.withValues(alpha: 0.7),
          //           size: 48,
          //         ),
          //       ),

          //       const SizedBox(height: 16),

          //       // Location info
          //       Padding(
          //         padding: const EdgeInsets.symmetric(horizontal: 16),
          //         child: Column(
          //           children: [
          //             if (camera.districtName != null &&
          //                 camera.districtName!.isNotEmpty)
          //               Container(
          //                 padding: const EdgeInsets.symmetric(
          //                   horizontal: 12,
          //                   vertical: 6,
          //                 ),
          //                 decoration: BoxDecoration(
          //                   color: Colors.black.withValues(alpha: 0.4),
          //                   borderRadius: BorderRadius.circular(20),
          //                   border: Border.all(
          //                     color: Colors.white.withValues(alpha: 0.2),
          //                   ),
          //                 ),
          //                 child: Row(
          //                   mainAxisSize: MainAxisSize.min,
          //                   children: [
          //                     Icon(
          //                       Icons.location_on,
          //                       color: Colors.white.withValues(alpha: 0.7),
          //                       size: 16,
          //                     ),
          //                     const SizedBox(width: 4),
          //                     Flexible(
          //                       child: Text(
          //                         camera.districtName!,
          //                         style: Theme.of(context).textTheme.bodySmall
          //                             ?.copyWith(
          //                               color: Colors.white.withValues(
          //                                 alpha: 0.9,
          //                               ),
          //                               fontWeight: FontWeight.w500,
          //                             ),
          //                         maxLines: 1,
          //                         overflow: TextOverflow.ellipsis,
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),

          //             const SizedBox(height: 8),

          //             // Status badge
          //             if (camera.workStatus != null)
          //               Container(
          //                 padding: const EdgeInsets.symmetric(
          //                   horizontal: 10,
          //                   vertical: 4,
          //                 ),
          //                 decoration: BoxDecoration(
          //                   color: _getStatusColor(
          //                     camera.workStatus,
          //                   ).withValues(alpha: 0.3),
          //                   borderRadius: BorderRadius.circular(12),
          //                   border: Border.all(
          //                     color: _getStatusColor(camera.workStatus),
          //                     width: 1.5,
          //                   ),
          //                 ),
          //                 child: Text(
          //                   camera.workStatus!,
          //                   style: Theme.of(context).textTheme.bodySmall
          //                       ?.copyWith(
          //                         color: _getStatusColor(camera.workStatus),
          //                         fontWeight: FontWeight.w600,
          //                         fontSize: 11,
          //                       ),
          //                 ),
          //               ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // Play button overlay - centered and prominent
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          // Bottom info overlay - ✅ FIXED: Changed Row to Center with constrained width
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min, // ✅ Use minimum space
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 14, // ✅ Reduced icon size
                    ),
                    const SizedBox(width: 4), // ✅ Reduced spacing
                    Flexible(
                      // ✅ Added Flexible to allow text to shrink
                      child: Text(
                        'Tap to play live',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 11, // ✅ Reduced font size
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Live indicator badge at top right
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryVideoStream(String cameraId, String videoUrl) async {
    try {
      // Dispose old controller completely
      final oldController = _cameraViewModel.vlcControllers[cameraId];
      if (oldController != null) {
        try {
          if (oldController.value.isPlaying) {
            await oldController.stop();
          }
          await oldController.dispose();
        } catch (e) {
          LogService.debug('Error disposing old controller: $e');
        }
      }

      _cameraViewModel.vlcControllers.remove(cameraId);
      _cameraViewModel.videoErrors.remove(cameraId);
      _cameraViewModel.isStreamPlaying.remove(cameraId);

      // Wait before retry
      await Future.delayed(const Duration(milliseconds: 1000));

      // Trigger rebuild to create new controller
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      LogService.debug('Error retrying stream: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cameraViewModel.searchController.dispose();
    _cameraViewModel.searchFocusNode.dispose();

    // Dispose all VLC controllers
    _disposeAllPlayers();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

enum DeviceType { phone, tablet, ipad }

class _InlineLiveBadge extends StatefulWidget {
  final double fontSize;

  const _InlineLiveBadge({required this.fontSize});

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
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
              const SizedBox(width: 4),
              Text(
                AppStrings.ksLive,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red,
                  fontSize: widget.fontSize - 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
