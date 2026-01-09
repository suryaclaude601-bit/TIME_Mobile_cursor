import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';
import 'package:go_router/go_router.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/core/config/shared_preferences/shared_preference_service.dart';
import 'package:streaming_dashboard/core/constants/api_constants.dart';
import 'package:streaming_dashboard/core/constants/api_endpoints.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/features/views/dashboard/model/camera_live_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/model/dashboard_count_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/model/installed_camera_model.dart';
import 'package:streaming_dashboard/services/api_service.dart';

class HomeViewModel extends ChangeNotifier {
  bool showGridView = false;
  bool isLoading = false;
  bool showFilterOptions = false;
  bool isFilterApplied = false;
  bool showReportsList = true;
  bool showAdvancedFilters = false;
  bool hasMoreData = true;
  bool isLoadingMore = false;

  String? errorMessage;
  String? selectedFilter;
  String? searchQuery = '';
  String? selectedDivision;
  String? selectedDistrict;
  String? selectedCategory;
  String? selectedStatus;

  List<String>? privileges;

  final Map<String, VlcPlayerController> vlcControllers = {};
  final Map<String, String?> videoErrors = {};
  final Map<String, Timer?> connectionTimers = {};
  final Map<String, bool> isStreamPlaying = {};

  CameraLiveModel? cameraData;
  DashboardCountModel? dashboardCountModel;
  CameraData? cameraUpdatedData;
  InstalledCameraModel? installedCameraCount;

  final TextEditingController searchController = TextEditingController();

  // Load more properties
  int currentPage = 1;
  int pageSize = 20;

  // Add this map to track which videos are playing
  final Map<String, bool> isVideoPlaying = {};

  // Add method to toggle video playback
  void toggleVideoPlayback(String cameraId) {
    isVideoPlaying[cameraId] = !(isVideoPlaying[cameraId] ?? false);
    notifyListeners();
  }

  Future<void> fetchCameraData(
    String fromStr,
    BuildContext context, {
    bool loadMore = false,
  }) async {
    if (!context.mounted) return;

    if (loadMore) {
      if (isLoadingMore || !hasMoreData) return;
      isLoadingMore = true;
      notifyListeners();
    } else {
      isLoading = true;
      currentPage = 1;
      hasMoreData = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoading = false;
        isLoadingMore = false;
        errorMessage = AppStrings.ksTokenNotFound;
        notifyListeners();
        if (context.mounted) {
          _handleAuthError(context);
        }
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      // Calculate skip value for pagination
      final skipValue = (currentPage - 1) * pageSize;

      final requestData = {
        "divisionIds": null,
        "districtIds": null,
        "tenderId": "",
        "divisionName": "",
        "districtName": "",
        "mainCategory": "",
        "subcategory": "",
        "workStatus": "",
        "tenderNumber": "",
        "channel": "",
        "rtspUrl": "",
        "liveUrl": "",
        "type": fromStr,
        "skip": skipValue, // Use calculated skip value
        "take": pageSize,
        "SearchString": "",
        "sorting": {"fieldName": "tenderNumber", "sort": "ASC"},
      };

      LogService.debug(
        '📄 Fetching page $currentPage (skip: $skipValue, take: $pageSize)',
      );

      final apiResponse = await ApiService.instance.post<CameraLiveModel>(
        endpoint: ApiConstants.baseUrl + ApiEndpoints.dashBoardCameraLiveAPI,
        data: requestData,
        fromJson: (json) => CameraLiveModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess && apiResponse.data != null) {
        final newData = apiResponse.data!.data ?? [];
        if (loadMore) {
          // Append new data to existing data
          if (cameraData?.data != null) {
            cameraData!.data!.addAll(newData);
          } else {
            cameraData = apiResponse.data;
          }

          // Check if there's more data
          hasMoreData = newData.length >= pageSize;

          if (hasMoreData) {
            currentPage++;
          }

          LogService.debug(
            '✅ Loaded ${newData.length} more cameras. Total: ${cameraData?.data?.length ?? 0}',
          );
        } else {
          // Replace data for initial load
          cameraData = apiResponse.data;
          hasMoreData = newData.length >= pageSize;

          if (hasMoreData) {
            currentPage++;
          }

          LogService.debug('✅ Initial load: ${newData.length} cameras');
        }

        isLoading = false;
        isLoadingMore = false;
        errorMessage = null;
        isFilterApplied = false;

        notifyListeners();
      } else {
        isLoading = false;
        isLoadingMore = false;
        errorMessage = apiResponse.error ?? AppStrings.ksFailedToFetch;

        if (errorMessage!.contains(AppStrings.ksAuthenticationFailed) ||
            errorMessage!.contains(AppStrings.ksAuthFailed)) {
          if (context.mounted) {
            _handleAuthError(context);
          }
        }
        notifyListeners();
      }
    } catch (e, _) {
      if (context.mounted) {
        isLoading = false;
        isLoadingMore = false;
        errorMessage = '${AppStrings.ksUnexpectedError} $e';
        LogService.debug('❌ Error fetching camera data: $e');
        notifyListeners();
      }
    }
  }

  Future<void> fetchFilteredCameraData(
    BuildContext context,
    Map<String, String?> filterParams,
  ) async {
    if (!context.mounted) return;

    isLoading = true;
    errorMessage = null;
    // Reset pagination for filtered data
    currentPage = 1;
    hasMoreData = false; // Disable load more for filtered results
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoading = false;
        errorMessage = AppStrings.ksTokenNotFound;
        notifyListeners();
        if (context.mounted) {
          _handleAuthError(context);
        }
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      final requestData = {
        "divisionIds": filterParams['divisionId'] != null
            ? [filterParams['divisionId']]
            : null,
        "districtIds": filterParams['districtId'] != null
            ? [filterParams['districtId']]
            : null,
        "tenderId": filterParams['tenderId'] ?? "",
        "divisionName": filterParams['divisionName'] ?? "",
        "districtName": filterParams['districtName'] ?? "",
        "mainCategory": filterParams['mainCategory'] ?? "",
        "subcategory": filterParams['subCategory'] ?? "",
        "workStatus": filterParams['workStatus'] ?? "",
        "tenderNumber": filterParams['tenderNumber'] ?? "",
        "channel": "",
        "rtspUrl": "",
        "liveUrl": "",
        "type": "Camera",
        "skip": 0,
        "take": 1000, // Load all filtered results
        "SearchString": filterParams['searchText'] ?? "",
        "sorting": {"fieldName": "tenderNumber", "sort": "ASC"},
      };

      LogService.debug('🔍 Filter request data: $requestData');

      final apiResponse = await ApiService.instance.post<CameraLiveModel>(
        endpoint: ApiConstants.baseUrl + ApiEndpoints.dashBoardCameraLiveAPI,
        data: requestData,
        fromJson: (json) => CameraLiveModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess && apiResponse.data != null) {
        cameraData = apiResponse.data;
        isLoading = false;
        errorMessage = null;
        isFilterApplied = true;
        notifyListeners();
      } else {
        isLoading = false;
        errorMessage = apiResponse.error ?? AppStrings.ksFailedToFetch;
        notifyListeners();
      }
    } catch (e, _) {
      if (context.mounted) {
        isLoading = false;
        errorMessage = '${AppStrings.ksUnexpectedError} $e';
        notifyListeners();
      }
    }
  }

  void applyFilteredData(CameraLiveModel filteredData) {
    cameraData = filteredData;
    isFilterApplied = true;
    isLoading = false;
    errorMessage = null;
    // Disable load more for filtered data
    hasMoreData = false;
    notifyListeners();
  }

  Future<void> clearFiltersAndReload(BuildContext context) async {
    isFilterApplied = false;
    selectedFilter = null;
    currentPage = 1;
    hasMoreData = true;
    await fetchCameraData('', context);
  }

  void _handleAuthError(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.ksSessionexpired),
        content: const Text(AppStrings.ksSessionExpired),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  int getStatusCount(String status) {
    if (cameraData?.data == null) return 0;
    return cameraData!.data!
        .where(
          (camera) => camera.workStatus?.toLowerCase() == status.toLowerCase(),
        )
        .length;
  }

  int getInvalidCameraCount() {
    if (cameraData?.data == null) return 0;
    return cameraData!.data!.where((camera) {
      final hasValidRtmpUrl =
          camera.rtmpUrl != null && camera.rtmpUrl!.isNotEmpty;
      final hasValidRtspUrl =
          camera.rtspUrl != null && camera.rtspUrl!.isNotEmpty;
      // final hasValidLiveUrl =
      //     camera.liveUrl != null && camera.liveUrl!.isNotEmpty;

      // Check if isRtspLive is false
      final isRtspLive = camera.isRtspLive ?? true;

      // Return cameras that don't have any valid URL OR isRtspLive is false
      return (!hasValidRtmpUrl || !hasValidRtspUrl) || !isRtspLive;
    }).length;
  }

  int getTotalCameraCount() {
    return cameraData?.data?.length ?? 0;
  }

  Future<void> loadData(
    HomeViewModel viewModel,
    BuildContext context,
    String fromStr,
  ) async {
    await viewModel.fetchCameraData(fromStr, context);
    notifyListeners();
  }
  // Add this method to your HomeViewModel class

  Future<void> fetchCameraAlertsData(BuildContext context) async {
    if (!context.mounted) return;

    isLoading = true;
    errorMessage = null;
    currentPage = 1;
    hasMoreData = false;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoading = false;
        errorMessage = AppStrings.ksTokenNotFound;
        notifyListeners();
        if (context.mounted) {
          _handleAuthError(context);
        }
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      final requestData = {
        "divisionIds": null,
        "districtIds": null,
        "tenderId": "",
        "divisionName": "",
        "districtName": "",
        "mainCategory": "",
        "subcategory": "",
        "workStatus": "",
        "tenderNumber": "",
        "channel": "",
        "rtspUrl": "",
        "liveUrl": "",
        "type": 'Alert',
        "skip": 0,
        "take": 1000,
        "SearchString": "",
        "sorting": {"fieldName": "tenderNumber", "sort": "ASC"},
      };
      print('req data $requestData');
      LogService.debug('🚨 Fetching camera alerts data');

      final apiResponse = await ApiService.instance.post<CameraLiveModel>(
        endpoint: ApiConstants.baseUrl + ApiEndpoints.dashBoardCameraLiveAPI,
        data: requestData,
        fromJson: (json) => CameraLiveModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess && apiResponse.data != null) {
        print('count data ${apiResponse.data!.data!.length}');
        final allCameras = apiResponse.data!.data ?? [];
        cameraData = apiResponse.data;
        // Filter cameras with invalid URLs or isRtspLive = false on client side
        // Filter only cameras where isRtspValid is false

        isLoading = false;
        errorMessage = null;
        isFilterApplied = true;
        notifyListeners();
      } else {
        isLoading = false;
        errorMessage = apiResponse.error ?? AppStrings.ksFailedToFetch;
        notifyListeners();
      }
    } catch (e) {
      LogService.debug('❌ Error fetching camera alerts: $e');
      if (context.mounted) {
        isLoading = false;
        errorMessage = '${AppStrings.ksUnexpectedError} $e';
        notifyListeners();
      }
    }
  }

  Future<void> handleRefresh(
    HomeViewModel viewModel,
    BuildContext context,
    String fromStr,
  ) async {
    // Reset pagination on refresh
    currentPage = 1;
    hasMoreData = true;
    await loadData(viewModel, context, fromStr);
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    // Dispose VLC controllers
    for (var controller in vlcControllers.values) {
      controller.dispose();
    }
    vlcControllers.clear();
    isVideoPlaying.clear(); // Clear playing state

    super.dispose();
  }

  // Add this property to your HomeViewModel class
  bool isLoadingDashboardCount = false;

  Future<void> getCameraCountAPI(BuildContext context) async {
    LogService.debug('🚀 START getCameraCountAPI');
    print('getCameraCountAPI');
    if (!context.mounted) {
      LogService.debug('❌ Context not mounted, aborting');
      return;
    }

    LogService.debug('📊 Setting loading state');
    isLoadingDashboardCount = true;
    errorMessage = null;
    notifyListeners();

    try {
      LogService.debug('🔑 Getting access token');
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        LogService.debug('❌ No access token found');
        errorMessage = AppStrings.ksTokenNotFound;
        isLoadingDashboardCount = false;
        notifyListeners();
        if (context.mounted) {
          _handleAuthError(context);
        }
        return;
      }

      LogService.debug('✅ Access token obtained');
      ApiService.instance.setAccessToken(accessToken);

      // Generate year list
      final yearsList = getYearList().map((year) => year.toString()).toList();

      // Prepare request data
      final requestData = {
        "departmentIds": null,
        "divisionIds": null,
        "selectionType": null,
        "costOrCount": "COUNT",
        "year": yearsList,
      };

      LogService.debug('📤 Sending request to API');
      LogService.debug('Request data: $requestData');
      LogService.debug(
        'Endpoint: ${ApiConstants.baseUrl}${ApiEndpoints.dashBoardCountAPI}',
      );

      // Make API call
      final apiResponse = await ApiService.instance.post<DashboardCountModel>(
        endpoint: ApiConstants.baseUrl + ApiEndpoints.dashBoardCountAPI,
        data: requestData,
        fromJson: (json) {
          LogService.debug('📥 Received response, parsing...');
          LogService.debug('Raw response: $json');
          return DashboardCountModel.fromJson(json);
        },
      );

      LogService.debug('📨 API call completed');

      if (!context.mounted) {
        LogService.debug('❌ Context unmounted after API call');
        return;
      }

      if (apiResponse.isSuccess && apiResponse.data != null) {
        dashboardCountModel = apiResponse.data;
        print('req data ${dashboardCountModel?.data?.totalProject}');

        LogService.debug('✅ Dashboard count loaded successfully');
        LogService.debug(
          'Total Projects: ${dashboardCountModel?.data?.totalProject}',
        );
        LogService.debug('Data: ${dashboardCountModel?.data}');

        isLoadingDashboardCount = false;
        errorMessage = null;
        notifyListeners();
      } else {
        LogService.debug('❌ API Error: ${apiResponse.error}');
        isLoadingDashboardCount = false;
        errorMessage = apiResponse.error ?? AppStrings.ksFailedToFetch;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      LogService.debug('❌ Exception in getCameraCountAPI: $e');
      LogService.debug('Stack trace: $stackTrace');

      if (context.mounted) {
        isLoadingDashboardCount = false;
        errorMessage = '${AppStrings.ksUnexpectedError} $e';
        notifyListeners();
      }
    } finally {
      LogService.debug('🏁 END getCameraCountAPI');
    }
  }

  // Helper method to get years as List<int>
  List<int> getYearList() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  Future<void> fetchInstalledCameraCount(BuildContext context) async {
    if (!context.mounted) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoading = false;
        errorMessage = AppStrings.ksTokenNotFound;
        notifyListeners();
        if (context.mounted) {
          _handleAuthError(context);
        }
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      final requestData = {
        "notStarted": "",
        "startedButStilled": "",
        "inProgress": "",
        "slowProgress": "",
        "completed": "",
        "total": "",
      };
      print('req data $requestData');
      LogService.debug('🚨 Fetching camera alerts data');

      final apiResponse = await ApiService.instance.post<InstalledCameraModel>(
        endpoint:
            ApiConstants.baseUrl +
            ApiEndpoints.getDashboardInstalledCameraCount,
        data: requestData,
        fromJson: (json) => InstalledCameraModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess && apiResponse.data != null) {
        installedCameraCount = apiResponse.data;
        print('count data ${installedCameraCount!.data?[0].total}');
        // Filter cameras with invalid URLs or isRtspLive = false on client side
        // Filter only cameras where isRtspValid is false

        isLoading = false;
        errorMessage = null;
        notifyListeners();
      } else {
        isLoading = false;
        errorMessage = apiResponse.error ?? AppStrings.ksFailedToFetch;
        notifyListeners();
      }
    } catch (e) {
      LogService.debug('❌ Error fetching camera alerts: $e');
      if (context.mounted) {
        isLoading = false;
        errorMessage = '${AppStrings.ksUnexpectedError} $e';
        notifyListeners();
      }
    }
  }
}
