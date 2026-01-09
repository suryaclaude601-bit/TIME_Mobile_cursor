import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/core/config/toast_service/toast_service.dart';
import 'package:streaming_dashboard/core/constants/app_asset_images.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/core/theme/app_themes.dart';
import 'package:streaming_dashboard/features/views/dashboard/data_model/home_view_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/model/camera_live_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/widget/vlcplayer_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  late HomeViewModel _viewModel;

  // Add VLC controllers map
  final Map<String, VlcPlayerController> _vlcControllers = {};
  late ScrollController _scrollController;
  final Map<String, bool> _volumeSet = {};

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _scrollController = ScrollController();

    // Add this line to show reports initially
    _viewModel.showReportsList = true;
    _viewModel.showGridView = false;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      loadData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }

    // Clean up off-screen players to save resources
    _cleanupOffScreenPlayers();
  }

  Future<void> _loadMoreData() async {
    if (_viewModel.isLoadingMore || !_viewModel.hasMoreData) return;

    if (_viewModel.searchController.text.isNotEmpty ||
        _viewModel.selectedFilter != null) {
      return;
    }

    await _viewModel.fetchCameraData('Camera', context, loadMore: true);
    if (mounted) setState(() {});
  }

  void _cleanupOffScreenPlayers() {
    final controllersToRemove = <String>[];

    for (var cameraId in _viewModel.vlcControllers.keys) {
      // if (!_viewModel.contains(cameraId)) {
      controllersToRemove.add(cameraId);
      // }
    }

    // Remove controllers that are no longer visible
    for (var cameraId in controllersToRemove) {
      _disposeController(cameraId);
    }
  }

  void _disposeController(String cameraId) {
    try {
      final controller = _viewModel.vlcControllers[cameraId];
      if (controller != null) {
        // Stop playback first
        if (controller.value.isPlaying) {
          controller.stop();
        }
        // Then dispose
        controller.dispose();
      }
      _viewModel.vlcControllers.remove(cameraId);
      _viewModel.videoErrors.remove(cameraId);
      _viewModel.isStreamPlaying.remove(cameraId);
    } catch (e) {
      LogService.debug('Error disposing controller for $cameraId: $e');
    }
  }

  Future<void> _handleRefresh() async {
    // Clear any existing video controllers before refresh
    _cleanupVideoControllers();

    // Reload all data
    await loadData();
  }

  // Get unique values for filters
  List<String> _getUniqueDivisions() {
    return _viewModel.cameraData?.data
            ?.map((e) => e.divisionName ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList() ??
        [];
  }

  List<String> _getUniqueDistricts() {
    return _viewModel.cameraData?.data
            ?.map((e) => e.districtName ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList() ??
        [];
  }

  List<String> _getUniqueCategories() {
    return _viewModel.cameraData?.data
            ?.map((e) => e.subcategory ?? e.mainCategory ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList() ??
        [];
  }

  List<String> _getUniqueStatuses() {
    return _viewModel.cameraData?.data
            ?.map((e) => e.workStatus ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList() ??
        [];
  }

  void _clearAllFilters() {
    setState(() {
      _viewModel.searchController.clear();
      _viewModel.searchQuery = '';
      _viewModel.selectedDivision = null;
      _viewModel.selectedDistrict = null;
      _viewModel.selectedCategory = null;
      _viewModel.selectedStatus = null;
      _viewModel.selectedFilter = null;
    });
  }

  Future<void> loadData() async {
    setState(() {
      _viewModel.isLoading = true; // ✓ Explicitly set loading state
    });
    // Then call camera count API
    if (mounted) {
      await _viewModel.fetchCameraData('Report', context);
      await _viewModel.getCameraCountAPI(context);
      // ignore: use_build_context_synchronously
      await _viewModel.fetchInstalledCameraCount(context);
    }
    // ignore: use_build_context_synchronously
    if (mounted) {
      setState(() {
        _viewModel.isLoading = false; // ✓ Explicitly clear loading state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // _buildHeader(constraints),
                _buildActionButtons(constraints),
                Expanded(child: _buildCameraGridView(constraints)),
              ],
            );
          },
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

  Widget _buildHeader(BoxConstraints constraints) {
    final deviceType = _getDeviceType(constraints);
    final isLargeScreen = deviceType == DeviceType.ipad;

    return Container(
      color: AppThemes.getSurfaceColor(context),
      padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: isLargeScreen ? 32 : 24,
            backgroundColor: Colors.grey,
            child: Icon(
              Icons.person,
              size: isLargeScreen ? 40 : 32,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isLargeScreen ? 24 : 16),
          Text(
            AppStrings.ksAdmin,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppThemes.getTextColor(context),
              fontSize: isLargeScreen ? 20 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BoxConstraints constraints) {
    final deviceType = _getDeviceType(constraints);
    final isLargeScreen = deviceType == DeviceType.ipad;
    final buttonPadding = isLargeScreen ? 14.0 : 12.0;
    final iconSize = isLargeScreen ? 34.0 : 32.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: buttonPadding,
            vertical: isLargeScreen ? 16.0 : 4.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    child: Container(
                      padding: EdgeInsets.all(isLargeScreen ? 12 : 4),

                      child: Image.asset(
                        gridImg,
                        width: iconSize,
                        height: iconSize,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        if (!_viewModel.showGridView) {
                          _viewModel.showGridView = true;
                          _viewModel.showFilterOptions = false;
                          _viewModel.selectedFilter = null;
                        } else if (!_viewModel.showFilterOptions) {
                          _viewModel.showFilterOptions = true;
                        } else {
                          _viewModel.showFilterOptions = false;
                          _viewModel.selectedFilter = null;
                        }
                      });
                    },
                  ),
                ],
              ),
              Stack(
                children: [
                  GestureDetector(
                    onTap: _navigateToFilter,
                    child: Container(
                      padding: EdgeInsets.all(isLargeScreen ? 12 : 4),
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
                  // Show blue dot indicator when filter is applied
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
              // Add clear filter button when filter is applied
              if (_viewModel.isFilterApplied) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    // Clean up video controllers when filter is cleared
                    _cleanupVideoControllers();

                    // Clear filters and reload
                    await _viewModel.clearFiltersAndReload(context);
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: EdgeInsets.all(isLargeScreen ? 6 : 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.clear,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _viewModel.showReportsList = !_viewModel.showReportsList;
                    if (_viewModel.showReportsList) {
                      _viewModel.showGridView = false;
                      _viewModel.showFilterOptions = true;

                      // Clean up video controllers when switching to reports
                      _cleanupVideoControllers();
                    } else {
                      _viewModel.showGridView = true;
                      _viewModel.showFilterOptions = true;
                    }
                  });
                },
                child: Text(
                  _viewModel.showReportsList
                      ? AppStrings.ksCamera
                      : AppStrings.ksReports,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemes.getTextColor(context),
                    fontSize: isLargeScreen ? 20 : 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     setState(() {
              //       _viewModel.showReportsList = !_viewModel.showReportsList;
              //       if (_viewModel.showReportsList) {
              //         _viewModel.showGridView = false;
              //         _viewModel.showFilterOptions = false;

              //         // Clean up video controllers when switching to reports
              //         _cleanupVideoControllers();
              //       } else {
              //         _viewModel.showGridView = true;
              //       }
              //     });
              //   },
              //   icon: Icon(
              //     _viewModel.showReportsList
              //         ? Icons.grid_view
              //         : Icons.analytics,
              //     color: AppThemes.getTextColor(context),
              //     size: isLargeScreen ? 20 : 18,
              //   ),
              //   label: Text(
              //     _viewModel.showReportsList
              //         ? AppStrings.ksCamera
              //         : AppStrings.ksReports,
              //     style: Theme.of(context).textTheme.titleLarge?.copyWith(
              //       color: AppThemes.getTextColor(context),
              //       fontSize: isLargeScreen ? 20 : 16,
              //       fontWeight: FontWeight.w400,
              //     ),
              //   ),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: _viewModel.showReportsList
              //         ? Theme.of(context).primaryColor
              //         : Theme.of(context).primaryColor.withValues(alpha: 0.8),
              //     padding: EdgeInsets.symmetric(
              //       horizontal: isLargeScreen ? 32 : 24,
              //       vertical: isLargeScreen ? 20 : 16,
              //     ),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        if (_viewModel.showFilterOptions)
          _buildFilterOptions(deviceType, buttonPadding),
      ],
    );
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

  Widget _buildSearchAndFilters(double horizontalPadding) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _viewModel.searchController,
                  onChanged: (value) {
                    setState(() {
                      _viewModel.searchQuery = value;
                    });
                  },
                  style: TextStyle(color: AppThemes.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: AppStrings.ksSearchBy,
                    hintStyle: TextStyle(
                      color: AppThemes.getTextColor(
                        context,
                      ).withValues(alpha: .5),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppThemes.getTextColor(context),
                      size: 20,
                    ),
                    suffixIcon: _viewModel.searchQuery!.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppThemes.getTextColor(context),
                              size: 20,
                            ),
                            onPressed: () {
                              _viewModel.searchController.clear();
                              setState(() {
                                _viewModel.searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppThemes.getSurfaceColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppThemes.getTextColor(
                          context,
                        ).withValues(alpha: .2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppThemes.getTextColor(
                          context,
                        ).withValues(alpha: .2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),

        // Advanced Filters Panel
        if (_viewModel.showAdvancedFilters)
          _buildAdvancedFiltersPanel(horizontalPadding),
      ],
    );
  }

  Widget _buildAdvancedFiltersPanel(double horizontalPadding) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemes.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemes.getTextColor(context).withValues(alpha: .2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.ksAdvancedFilters,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemes.getTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  AppStrings.ksClearAll,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Division Filter
          _buildFilterDropdown(
            label: AppStrings.ksDivision,
            value: _viewModel.selectedDivision,
            items: _getUniqueDivisions(),
            onChanged: (value) {
              setState(() {
                _viewModel.selectedDivision = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // District Filter
          _buildFilterDropdown(
            label: AppStrings.ksDistrict,
            value: _viewModel.selectedDistrict,
            items: _getUniqueDistricts(),
            onChanged: (value) {
              setState(() {
                _viewModel.selectedDistrict = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Category Filter
          _buildFilterDropdown(
            label: AppStrings.ksCategory,
            value: _viewModel.selectedCategory,
            items: _getUniqueCategories(),
            onChanged: (value) {
              setState(() {
                _viewModel.selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Status Filter
          _buildFilterDropdown(
            label: 'Status',
            value: _viewModel.selectedStatus,
            items: _getUniqueStatuses(),
            onChanged: (value) {
              setState(() {
                _viewModel.selectedStatus = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppThemes.getTextColor(context).withValues(alpha: .7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppThemes.getBackgroundColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppThemes.getTextColor(context).withValues(alpha: .2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Select $label',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemes.getTextColor(context).withValues(alpha: .5),
                  fontSize: 14,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppThemes.getTextColor(context),
              ),
              dropdownColor: AppThemes.getSurfaceColor(context),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppThemes.getTextColor(context),
                fontSize: 14,
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All $label'),
                ),
                ...items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildFilterOptions(DeviceType deviceType, double horizontalPadding) {
  //   final isLargeScreen = deviceType == DeviceType.ipad;
  //   final fontSize = isLargeScreen ? 16.0 : 14.0;

  //   final filters = [
  //     {
  //       'label': AppStrings.ksTotalWorks,
  //       'value': AppStrings.ksall,
  //       'count': _viewModel.dashboardCountModel?.data?.totalProject,
  //       'icon': Icons.work_outline,
  //     },
  //     {
  //       'label': AppStrings.ksNotStarted,
  //       'value': AppStrings.ksNotstarted,
  //       'count': _viewModel.dashboardCountModel?.data?.projectUpcoming,
  //       'icon': Icons.not_started,
  //     },
  //     {
  //       'label': AppStrings.ksInprogress,
  //       'value': AppStrings.ksInProgress,
  //       'count': _viewModel.dashboardCountModel?.data?.projectOnGoing,
  //       'icon': Icons.refresh,
  //     },
  //     {
  //       'label': AppStrings.ksSlowProgress,
  //       'value': AppStrings.ksSlowprogress,
  //       'count': _viewModel.dashboardCountModel?.data?.projectSlowprogress,
  //       'icon': Icons.access_time,
  //     },
  //     {
  //       'label': AppStrings.ksStartedButStilled,
  //       'value': AppStrings.ksStartedButStilled,
  //       'count': _viewModel.dashboardCountModel?.data?.projectOnHold,
  //       'icon': Icons.access_time,
  //     },
  //     {
  //       'label': AppStrings.ksCompleted,
  //       'value': AppStrings.kscompleted,
  //       'count': _viewModel.dashboardCountModel?.data?.projectFinished,
  //       'icon': Icons.check_circle_outline,
  //     },
  //   ];

  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeInOut,
  //     padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
  //     child: Column(
  //       children: [
  //         Wrap(
  //           spacing: 8,
  //           runSpacing: 8,
  //           children: filters.map((filter) {
  //             final isSelected =
  //                 _viewModel.selectedFilter == filter['value'] ||
  //                 (_viewModel.selectedFilter == null &&
  //                     filter['value'] == 'all');

  //             return GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   if (filter['value'] == 'all') {
  //                     _viewModel.selectedFilter = null;
  //                   } else {
  //                     _viewModel.selectedFilter = filter['value'] as String;
  //                   }
  //                 });
  //               },
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 12,
  //                   vertical: 8,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: isSelected
  //                       ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
  //                       : AppThemes.getTextColor(
  //                           context,
  //                         ).withValues(alpha: 0.15),
  //                   borderRadius: BorderRadius.circular(8),
  //                   border: Border.all(
  //                     color: isSelected
  //                         ? Theme.of(context).primaryColor
  //                         : AppThemes.getTextColor(
  //                             context,
  //                           ).withValues(alpha: 0.2),
  //                     width: isSelected ? 2 : 1,
  //                   ),
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(
  //                       filter['icon'] as IconData,
  //                       color: AppThemes.getTextColor(context),
  //                       size: fontSize + 2,
  //                     ),
  //                     const SizedBox(width: 6),
  //                     Text(
  //                       '${filter['count']}',
  //                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                         color: AppThemes.getTextColor(context),
  //                         fontSize: fontSize,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 4),
  //                     Text(
  //                       filter['label'] as String,
  //                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                         color: AppThemes.getTextColor(context),
  //                         fontSize: fontSize,
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }).toList(),
  //         ),
  //         const SizedBox(height: 8),
  //         GestureDetector(
  //           onTap: () async {
  //             setState(() {
  //               _viewModel.selectedFilter = 'camera-alerts';
  //             });

  //             // Call API to fetch camera alerts
  //             await _viewModel.fetchCameraAlertsData(context);
  //           },
  //           child: Container(
  //             width: double.infinity,
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //             decoration: BoxDecoration(
  //               color: _viewModel.selectedFilter == 'camera-alerts'
  //                   ? Colors.red.withValues(alpha: 0.3)
  //                   : AppThemes.getTextColor(context).withValues(alpha: 0.15),
  //               borderRadius: BorderRadius.circular(8),
  //               border: Border.all(
  //                 color: _viewModel.selectedFilter == 'camera-alerts'
  //                     ? Colors.red
  //                     : AppThemes.getTextColor(context).withValues(alpha: 0.2),
  //                 width: _viewModel.selectedFilter == 'camera-alerts' ? 2 : 1,
  //               ),
  //             ),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(
  //                   Icons.camera_alt,
  //                   color: AppThemes.getTextColor(context),
  //                   size: fontSize + 2,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   '${_viewModel.getInvalidCameraCount()}',
  //                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                     color: AppThemes.getTextColor(context),
  //                     fontSize: fontSize,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   AppStrings.ksCameraAlerts,
  //                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                     color: AppThemes.getTextColor(context),
  //                     fontSize: fontSize,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildFilterOptions(DeviceType deviceType, double horizontalPadding) {
    final isLargeScreen = deviceType == DeviceType.ipad;
    final fontSize = isLargeScreen ? 16.0 : 14.0;

    final filters = [
      {
        'label': AppStrings.ksTotalWorks,
        'value': AppStrings.ksall,
        'count': _viewModel.dashboardCountModel?.data?.totalProject,
        'icon': Icons.work_outline,
      },
      {
        'label': AppStrings.ksNotStarted,
        'value': AppStrings.ksNotstarted,
        'count': _viewModel.dashboardCountModel?.data?.projectUpcoming,
        'icon': Icons.not_started,
      },
      {
        'label': AppStrings.ksInprogress,
        'value': AppStrings.ksInProgress,
        'count': _viewModel.dashboardCountModel?.data?.projectOnGoing,
        'icon': Icons.refresh,
      },
      {
        'label': AppStrings.ksSlowProgress,
        'value': AppStrings.ksSlowprogress,
        'count': _viewModel.dashboardCountModel?.data?.projectSlowprogress,
        'icon': Icons.access_time,
      },
      {
        'label': AppStrings.ksStartedButStilled,
        'value': AppStrings.ksStartedButStilled,
        'count': _viewModel.dashboardCountModel?.data?.projectOnHold,
        'icon': Icons.access_time,
      },
      {
        'label': AppStrings.ksCompleted,
        'value': AppStrings.kscompleted,
        'count': _viewModel.dashboardCountModel?.data?.projectFinished,
        'icon': Icons.check_circle_outline,
      },
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),

      child: Column(
        children: [
          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((filter) {
              final isSelected =
                  _viewModel.selectedFilter == filter['value'] ||
                  (_viewModel.selectedFilter == null &&
                      filter['value'] == 'all');

              return GestureDetector(
                onTap: () async {
                  _cleanupVideoControllers();

                  setState(() {
                    _viewModel.isLoading = true;
                    if (filter['value'] == 'all') {
                      _viewModel.selectedFilter = null;
                    } else {
                      _viewModel.selectedFilter = filter['value'] as String;
                    }
                  });

                  if (_viewModel.showReportsList) {
                    await _viewModel.fetchCameraData('Report', context);
                  } else {
                    await _viewModel.fetchCameraData('Camera', context);
                  }

                  if (mounted) setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                        : AppThemes.getTextColor(
                            context,
                          ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : AppThemes.getTextColor(
                              context,
                            ).withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        color: AppThemes.getTextColor(context),
                        size: fontSize + 2,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${filter['count']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppThemes.getTextColor(context),
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        filter['label'] as String,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppThemes.getTextColor(context),
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Camera alerts button
          GestureDetector(
            onTap: () async {
              _cleanupVideoControllers();

              setState(() {
                _viewModel.isLoading = true;
                _viewModel.selectedFilter = 'camera-alerts';
              });

              await _viewModel.fetchCameraAlertsData(context);

              if (mounted) setState(() {});
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _viewModel.selectedFilter == 'camera-alerts'
                    ? Colors.red.withValues(alpha: 0.3)
                    : AppThemes.getTextColor(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _viewModel.selectedFilter == 'camera-alerts'
                      ? Colors.red
                      : AppThemes.getTextColor(context).withValues(alpha: 0.2),
                  width: _viewModel.selectedFilter == 'camera-alerts' ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: AppThemes.getTextColor(context),
                    size: fontSize + 2,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_viewModel.getInvalidCameraCount()}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppThemes.getTextColor(context),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.ksCameraAlerts,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppThemes.getTextColor(context),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // NEW: Camera Installation Stats Card
          if (_viewModel.installedCameraCount?.data != null &&
              _viewModel.installedCameraCount!.data!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppThemes.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppThemes.getTextColor(context).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Camera Installation Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppThemes.getTextColor(context),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Header with icon
                  // Row(
                  //   children: [
                  //     Container(
                  //       padding: const EdgeInsets.all(12),
                  //       decoration: BoxDecoration(
                  //         color: Theme.of(
                  //           context,
                  //         ).primaryColor.withValues(alpha: 0.2),
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       child: Icon(
                  //         Icons.videocam,
                  //         color: Theme.of(context).primaryColor,
                  //         size: 20,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 2),
                  //     Text(
                  //       'Camera Installation Status',
                  //       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  //         color: AppThemes.getTextColor(context),
                  //         fontSize: fontSize,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  // Total stats
                  // Container(
                  //   padding: const EdgeInsets.all(12),
                  //   decoration: BoxDecoration(
                  //     color: Theme.of(
                  //       context,
                  //     ).primaryColor.withValues(alpha: 0.1),
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text(
                  //               'Total Works',
                  //               style: Theme.of(context).textTheme.bodyMedium
                  //                   ?.copyWith(
                  //                     color: AppThemes.getTextColor(
                  //                       context,
                  //                     ).withValues(alpha: 0.7),
                  //                     fontSize: fontSize - 2,
                  //                   ),
                  //             ),
                  //             const SizedBox(height: 4),
                  //             Text(
                  //               '${_viewModel.installedCameraCount!.data![0].total ?? 0}',
                  //               style: Theme.of(context)
                  //                   .textTheme
                  //                   .headlineMedium
                  //                   ?.copyWith(
                  //                     color: AppThemes.getTextColor(context),
                  //                     fontSize: fontSize + 8,
                  //                     fontWeight: FontWeight.bold,
                  //                   ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //       Container(
                  //         height: 50,
                  //         width: 1,
                  //         color: AppThemes.getTextColor(
                  //           context,
                  //         ).withValues(alpha: 0.2),
                  //       ),
                  //       // Expanded(
                  //       //   child: Column(
                  //       //     crossAxisAlignment: CrossAxisAlignment.end,
                  //       //     children: [
                  //       //       Text(
                  //       //         'Cameras Installed',
                  //       //         style: Theme.of(context).textTheme.bodyMedium
                  //       //             ?.copyWith(
                  //       //               color: AppThemes.getTextColor(
                  //       //                 context,
                  //       //               ).withValues(alpha: 0.7),
                  //       //               fontSize: fontSize - 2,
                  //       //             ),
                  //       //       ),
                  //       //       const SizedBox(height: 4),
                  //       //       Text(
                  //       //         '${_viewModel.installedCameraCount!.data![0].total ?? 0}',
                  //       //         style: Theme.of(context)
                  //       //             .textTheme
                  //       //             .headlineMedium
                  //       //             ?.copyWith(
                  //       //               color: Colors.green,
                  //       //               fontSize: fontSize + 8,
                  //       //               fontWeight: FontWeight.bold,
                  //       //             ),
                  //       //       ),
                  //       //     ],
                  //       //   ),
                  //       // ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 6),
                  _buildInstallationStatusRow(
                    'Total installed Cameras',
                    int.tryParse(
                          _viewModel.installedCameraCount!.data![0].total
                                  ?.toString() ??
                              '0',
                        ) ??
                        0,
                    Colors.grey,
                    fontSize,
                  ),
                  const SizedBox(height: 4),
                  // Detailed breakdown

                  // Detailed breakdown
                  _buildInstallationStatusRow(
                    'Not Started',
                    int.tryParse(
                          _viewModel.installedCameraCount!.data![0].notStarted
                                  ?.toString() ??
                              '0',
                        ) ??
                        0,
                    Colors.orange,
                    fontSize,
                  ),
                  const SizedBox(height: 4),

                  // const SizedBox(height: 8),
                  _buildInstallationStatusRow(
                    'Started But Stilled',
                    int.tryParse(
                          _viewModel
                                  .installedCameraCount!
                                  .data![0]
                                  .startedButStilled
                                  ?.toString() ??
                              '0',
                        ) ??
                        0,

                    Colors.amber,
                    fontSize,
                  ),
                  const SizedBox(height: 4),
                  _buildInstallationStatusRow(
                    'In Progress',
                    int.tryParse(
                          _viewModel.installedCameraCount!.data![0].inProgress
                                  ?.toString() ??
                              '0',
                        ) ??
                        0,
                    Colors.blue,
                    fontSize,
                  ),
                  const SizedBox(height: 4),
                  _buildInstallationStatusRow(
                    'Slow Progress',
                    int.tryParse(
                          _viewModel.installedCameraCount!.data![0].slowProgress
                                  ?.toString() ??
                              '0',
                        ) ??
                        0,
                    Colors.deepOrange,
                    fontSize,
                  ),
                  const SizedBox(height: 4),
                  _buildInstallationStatusRow(
                    'Completed',
                    int.tryParse(
                          _viewModel.installedCameraCount!.data![0].completed
                                  ?.toString() ??
                              '0',
                        ) ??
                        0,
                    Colors.green,
                    fontSize,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstallationStatusRow(
    String label,
    int count,
    Color color,
    double fontSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Container(
            //   width: 8,
            //   height: 8,
            //   decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            // ),
            // const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemes.getTextColor(context),
                fontSize: fontSize - 1,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<CameraData> _applyFilters(List<CameraData> data) {
    List<CameraData> filtered = data;

    // Apply search query
    if (_viewModel.searchQuery!.isNotEmpty) {
      filtered = filtered.where((camera) {
        final query = _viewModel.searchQuery!.toLowerCase();
        return (camera.districtName?.toLowerCase().contains(query) ?? false) ||
            (camera.divisionName?.toLowerCase().contains(query) ?? false) ||
            (camera.tenderNumber?.toLowerCase().contains(query) ?? false) ||
            (camera.workStatus?.toLowerCase().contains(query) ?? false) ||
            (camera.mainCategory?.toLowerCase().contains(query) ?? false) ||
            (camera.subcategory?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply division filter
    if (_viewModel.selectedDivision != null) {
      filtered = filtered
          .where((camera) => camera.divisionName == _viewModel.selectedDivision)
          .toList();
    }

    // Apply district filter
    if (_viewModel.selectedDistrict != null) {
      filtered = filtered
          .where((camera) => camera.districtName == _viewModel.selectedDistrict)
          .toList();
    }

    // Apply category filter
    if (_viewModel.selectedCategory != null) {
      filtered = filtered.where((camera) {
        final category = camera.subcategory ?? camera.mainCategory;
        return category == _viewModel.selectedCategory;
      }).toList();
    }

    // Apply status filter
    if (_viewModel.selectedStatus != null) {
      filtered = filtered
          .where((camera) => camera.workStatus == _viewModel.selectedStatus)
          .toList();
    }

    // Apply quick filter from grid view
    if (_viewModel.selectedFilter == 'camera-alerts') {
      filtered = filtered.where((camera) {
        final hasValidRtmpUrl =
            camera.rtmpUrl != null && camera.rtmpUrl!.isNotEmpty;
        final hasValidRtspUrl =
            camera.rtspUrl != null && camera.rtspUrl!.isNotEmpty;
        final isRtspLive = camera.isRtspLive ?? true;

        // Return cameras that don't have valid URLs OR isRtspLive is false
        return (!hasValidRtmpUrl || !hasValidRtspUrl) || !isRtspLive;
      }).toList();
    }
    // Apply quick filter for work status (only if not camera-alerts)
    else if (_viewModel.selectedFilter != null &&
        _viewModel.selectedFilter != 'all') {
      filtered = filtered
          .where(
            (camera) =>
                camera.workStatus?.toLowerCase() ==
                _viewModel.selectedFilter!.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  Widget _buildCameraGridView(BoxConstraints constraints) {
    final deviceType = _getDeviceType(constraints);
    final padding = deviceType == DeviceType.ipad ? 24.0 : 16.0;

    if (_viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppThemes.getTextColor(context),
        ),
      );
    }

    if (_viewModel.errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Theme.of(context).primaryColor,
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppThemes.getTextColor(context),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: const Text(AppStrings.ksRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Apply all filters
    List<CameraData> filteredCameras = _applyFilters(
      _viewModel.cameraData?.data ?? [],
    );

    if (filteredCameras.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Theme.of(context).primaryColor,
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
                    color: AppThemes.getTextColor(
                      context,
                    ).withValues(alpha: 0.5),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.ksNoResultsFound,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppThemes.getTextColor(context),
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: Text(
                      AppStrings.ksClearFilters,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show Reports List or Grid View with RefreshIndicator
    if (_viewModel.showReportsList) {
      return _buildReportsList(padding, filteredCameras);
    }

    // ✅ REMOVED the outer Expanded widget here
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Theme.of(context).primaryColor,
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
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildReportsList(double padding, List<CameraData> filteredData) {
    // Add loader for initial report list loading
    if (_viewModel.isLoading && filteredData.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppThemes.getTextColor(context),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final camera = filteredData[index];
          return _buildReportCard(camera);
        },
      ),
    );
  }

  Widget _buildReportCard(CameraData camera) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
      color: AppThemes.getSurfaceColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppThemes.getTextColor(context).withValues(alpha: .1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (camera.rtmpUrl == null || camera.rtmpUrl!.isEmpty) {
            ToastService.showError(AppStrings.ksVideoURLNotAvailable);
            return;
          }
          context.push('/live_camera', extra: camera);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced from 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      camera.tenderNumber ?? AppStrings.ksNA,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppThemes.getTextColor(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 11, // Reduced from 14
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(camera.workStatus),
                ],
              ),
              const SizedBox(height: 8), // Reduced from 12
              _buildInfoRow(
                Icons.business,
                AppStrings.ksDivision,
                camera.divisionName ?? AppStrings.ksNA,
              ),
              const SizedBox(height: 6), // Reduced from 8
              _buildInfoRow(
                Icons.location_on,
                AppStrings.ksDistrict,
                camera.districtName ?? AppStrings.ksNA,
              ),
              const SizedBox(height: 6), // Reduced from 8
              _buildInfoRow(
                Icons.category,
                AppStrings.ksCategory,
                camera.subcategory ?? camera.mainCategory ?? AppStrings.ksNA,
              ),
              // const SizedBox(height: 6), // Reduced from 8
              // _buildInfoRow(
              //   Icons.calendar_today,
              //   AppStrings.ksDate,
              //   _formatTimestamp(),
              // ),
              // if (camera.rtmpUrl == null || camera.rtmpUrl!.isEmpty)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 8), // Reduced from 12
              //     child: Container(
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 10, // Reduced from 12
              //         vertical: 5, // Reduced from 6
              //       ),
              //       decoration: BoxDecoration(
              //         color: Colors.red.withValues(alpha: 0.1),
              //         borderRadius: BorderRadius.circular(8),
              //         border: Border.all(
              //           color: Colors.red.withValues(alpha: 0.3),
              //         ),
              //       ),
              //       child: Row(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           const Icon(
              //             Icons.videocam_off,
              //             color: Colors.red,
              //             size: 14, // Reduced from 16
              //           ),
              //           const SizedBox(width: 6),
              //           Text(
              //             AppStrings.ksCameraAvailable,
              //             style: Theme.of(context).textTheme.titleLarge
              //                 ?.copyWith(
              //                   color: Colors.red,
              //                   fontWeight: FontWeight.w500,
              //                   fontSize: 11, // Reduced from 12
              //                 ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14, // Reduced from 16
          color: AppThemes.getTextColor(context).withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6), // Reduced from 8
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppThemes.getTextColor(context).withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
            fontSize: 12, // Reduced from 13
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppThemes.getTextColor(context),
              fontWeight: FontWeight.w500,
              fontSize: 12, // Reduced from 13
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color statusColor;
    switch (status?.toLowerCase()) {
      // case 'in-progress':
      //   statusColor = Colors.green;
      //   break;
      // case 'not-started':
      //   statusColor = Colors.orange;
      //   break;
      // case 'completed':
      //   statusColor = Colors.blue;
      //   break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ), // Reduced
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: .5)),
      ),
      child: Text(
        status ?? AppStrings.ksUnknown,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w500,
          fontSize: 11, // Reduced from 12
        ),
      ),
    );
  }

  Widget _buildCameraCard(CameraData camera, DeviceType deviceType) {
    final fontSize = deviceType == DeviceType.ipad ? 12.0 : 10.0;
    final cameraId =
        camera.tenderId ??
        camera.tenderNumber ??
        '${camera.divisionName}_${camera.districtName}';
    final videoHeight = deviceType == DeviceType.ipad ? 200.0 : 160.0;

    return GestureDetector(
      onTap: () {
        if (camera.rtmpUrl == null || camera.rtmpUrl!.isEmpty) {
          ToastService.showError(AppStrings.ksVideoURLNotAvailable);
          return;
        }
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
            // Title section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                camera.tenderNumber ?? AppStrings.ksNA,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemes.getTextColor(context),
                  fontWeight: FontWeight.w400,
                  fontSize: fontSize,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    camera.workStatus,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getStatusColor(camera.workStatus),
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
                          color: _getStatusColor(camera.workStatus),
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Video player section
            Container(
              height: videoHeight,
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
                child: _viewModel.showGridView && !_viewModel.showReportsList
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: _buildVideoPlayer(cameraId, camera),
                          ),
                          if (_viewModel.videoErrors[cameraId] == null)
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
                              (camera.rtmpUrl != null &&
                                          camera.rtmpUrl!.isNotEmpty) ||
                                      (camera.rtspUrl != null &&
                                          camera.rtspUrl!.isNotEmpty)
                                  ? Icons.play_circle_outline
                                  : Icons.videocam_off,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 64,
                            ),
                            if ((camera.rtmpUrl != null &&
                                    camera.rtmpUrl!.isNotEmpty) ||
                                (camera.rtspUrl != null &&
                                    camera.rtspUrl!.isNotEmpty))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Tap to view live',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: fontSize,
                                      ),
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

  void _safeDisposeController(VlcPlayerController controller) {
    try {
      // Check if controller is initialized before disposing
      if (controller.value.isInitialized) {
        if (controller.value.isPlaying) {
          controller.stop();
        }
        controller.dispose();
      }
    } catch (e) {
      LogService.debug('Error disposing VLC controller: $e');
    }
  }

  void _cleanupVideoControllers() {
    for (var controller in _vlcControllers.values) {
      _safeDisposeController(controller);
    }
    _vlcControllers.clear();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      // case 'in-progress':
      //   return Colors.green;
      // case 'not-started':
      //   return Colors.orange;
      // case 'completed':
      //   return Colors.blue;
      default:
        return Colors.grey;
    }
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

  // Add default thumbnail widget
  Widget _buildDefaultThumbnail() {
    return Container(
      color: Colors.grey.shade900,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam,
            color: Colors.white.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: 8),
          Text(
            'No thumbnail available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up all video controllers
    for (var cameraId in _vlcControllers.keys.toList()) {
      final controller = _vlcControllers[cameraId];
      if (controller != null) {
        try {
          if (controller.value.isPlaying) {
            controller.stop();
          }
          controller.dispose();
        } catch (e) {
          LogService.debug('Error disposing controller for $cameraId: $e');
        }
      }
    }
    _vlcControllers.clear();
    _volumeSet.clear();
    _viewModel.isVideoPlaying.clear();

    _viewModel.searchController.dispose();
    _scrollController.dispose();
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
                  fontWeight: FontWeight.w500,
                  fontSize: widget.fontSize - 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
