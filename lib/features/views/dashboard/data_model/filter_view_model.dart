import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/core/config/shared_preferences/shared_preference_service.dart';
import 'package:streaming_dashboard/core/constants/api_constants.dart';
import 'package:streaming_dashboard/core/constants/api_endpoints.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/features/views/camera/model/district_list_model.dart';
import 'package:streaming_dashboard/features/views/camera/model/division_list_model.dart';
import 'package:streaming_dashboard/features/views/camera/model/sub_work_type_model.dart';
import 'package:streaming_dashboard/features/views/camera/model/tender_number_model.dart';
import 'package:streaming_dashboard/features/views/camera/model/work_status_model.dart';
import 'package:streaming_dashboard/features/views/camera/model/work_type_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/model/camera_live_model.dart';
import 'package:streaming_dashboard/services/api_service.dart';

class FilterViewModel extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  String? selectedDivision;
  String? selectedDivisionId;

  String? selectedDistrict;
  String? selectedDistrictId;

  String? selectedWorkType;
  String? selectedSubWorkType;
  String? selectedWorkStatus;

  String? selectedTenderNumber;
  String? selectedTenderNumberId;

  bool isLoading = false;
  String? errorMessage;

  // Individual loading states for each dropdown
  bool isLoadingDivisions = false;
  bool isLoadingDistricts = false;
  bool isLoadingWorkTypes = false;
  bool isLoadingSubWorkTypes = false;
  bool isLoadingWorkStatus = false;
  bool isLoadingTenderNumbers = false;

  DivisionListModel? divisionList;
  DistrictListModel? districtList;
  WorkTypeModel? workTypeList;
  SubWorkTypeModel? subWorkTypeList;
  WorkStatusModel? workStatusList;
  TenderNumberModel? tenderNumberList;

  List<DivisionData> _allDivisionList = [];
  List<DivisionData> get allDivisionList => _allDivisionList;

  List<DistrictData> _allDistrictList = [];
  List<DistrictData> get allDistrictList => _allDistrictList;

  List<WorkTypeData> _allWorkTypeList = [];
  List<WorkTypeData> get allWorkTypeList => _allWorkTypeList;

  List<SubWorkTypeData> _allSubWorkTypeList = [];
  List<SubWorkTypeData> get allSubWorkTypeList => _allSubWorkTypeList;

  List<WorkStatusData> _allWorkStatusList = [];
  List<WorkStatusData> get allWorkStatusList => _allWorkStatusList;

  List<TenderNumberData> _allTenderNumberList = [];
  List<TenderNumberData> get allTenderNumberList => _allTenderNumberList;

  List<String> get allDivisionListArray => _allDivisionList
      .map((e) => e.divisionName ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  List<String> get allDistrictListArray => _allDistrictList
      .map((e) => e.districtName ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  List<String> get allWorkListArray => _allWorkTypeList
      .map((e) => e.mainCategory ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  List<String> get allSubWorkListArray => _allSubWorkTypeList
      .map((e) => e.subCategory ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  List<String> get allWorkStatusListArray => _allWorkStatusList
      .map((e) => e.workStatus ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  List<String> get allTenderNumberListArray => _allTenderNumberList
      .map((e) => e.tenderNumber ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();
  // In FilterViewModel
  List<dynamic> get filteredDistrictList => _filteredDistrictList.isNotEmpty
      ? _filteredDistrictList
      : allDistrictList;
  List<dynamic> _filteredDistrictList = [];
  List<String> get filteredDistrictListArray => _filteredDistrictList
      .map((e) => e.toJson()['districtName']?.toString() ?? '')
      .toList();
  // Fetch all divisions (no dependencies)
  Future<void> fetchAllDivisionList(BuildContext context) async {
    if (!context.mounted) return;
    isLoadingDivisions = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoadingDivisions = false;
        errorMessage = AppStrings.ksTokenNotFound;
        notifyListeners();
        if (context.mounted) context.go('/login');
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      final apiResponse = await ApiService.instance.post(
        endpoint: '${ApiConstants.baseUrl}${ApiEndpoints.getAllDivisionAPI}',
        data: {},
        fromJson: (json) => DivisionListModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess == true && apiResponse.data != null) {
        divisionList = apiResponse.data;
        _allDivisionList = divisionList?.data ?? [];
      }
    } catch (e) {
      errorMessage = '${AppStrings.ksFailedToFetch} $e';
    } finally {
      isLoadingDivisions = false;
      notifyListeners();
    }
  }

  // Fetch all districts (independent - can be called without division selection)
  Future<void> fetchAllDistricts(
    BuildContext context, {
    String? divisionId,
  }) async {
    if (!context.mounted) return;
    isLoadingDistricts = true;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoadingDistricts = false;
        if (context.mounted) context.go('/login');
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      // Build request with optional divisionId
      final requestData = <String, dynamic>{};
      if (divisionId != null && divisionId.isNotEmpty) {
        requestData["divisionIds"] = [divisionId];
      }

      final apiResponse = await ApiService.instance.post(
        endpoint: '${ApiConstants.baseUrl}${ApiEndpoints.getDistrictAPI}',
        data: requestData,
        fromJson: (json) => DistrictListModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess == true && apiResponse.data != null) {
        districtList = apiResponse.data;
        _allDistrictList = districtList?.data ?? [];

        // Update filtered list
        if (divisionId != null && divisionId.isNotEmpty) {
          _filteredDistrictList = List.from(_allDistrictList);
        } else {
          _filteredDistrictList = List.from(_allDistrictList);
        }
      }
    } catch (e) {
      LogService.debug('Error fetching districts: $e');
    } finally {
      isLoadingDistricts = false;
      notifyListeners();
    }
  }

  // Fetch all work types (independent)
  Future<void> fetchAllWorkTypes(BuildContext context) async {
    if (!context.mounted) return;
    isLoadingWorkTypes = true;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoadingWorkTypes = false;
        if (context.mounted) context.go('/login');
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      // Build query params - all are optional
      String queryParams = '';
      List<String> params = [];

      if (selectedDivisionId != null && selectedDivisionId!.isNotEmpty) {
        params.add('divisionId=$selectedDivisionId');
      }
      if (selectedDistrictId != null && selectedDistrictId!.isNotEmpty) {
        params.add('districtId=$selectedDistrictId');
      }

      if (params.isNotEmpty) {
        queryParams = '?${params.join('&')}';
      }

      final apiResponse = await ApiService.instance.post(
        endpoint:
            '${ApiConstants.baseUrl}${ApiEndpoints.getWorkTypeAPI}$queryParams',
        fromJson: (json) => WorkTypeModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess == true && apiResponse.data != null) {
        workTypeList = apiResponse.data;
        _allWorkTypeList = workTypeList?.data ?? [];
      }
    } catch (e) {
      LogService.debug('Error fetching work types: $e');
    } finally {
      isLoadingWorkTypes = false;
      notifyListeners();
    }
  }

  // Fetch all sub work types (independent)
  Future<void> fetchAllSubWorkTypes(BuildContext context) async {
    if (!context.mounted) return;
    isLoadingSubWorkTypes = true;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoadingSubWorkTypes = false;
        if (context.mounted) context.go('/login');
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      // Build query params - all are optional
      List<String> params = [];

      if (selectedDivisionId != null && selectedDivisionId!.isNotEmpty) {
        params.add('divisionId=$selectedDivisionId');
      }
      if (selectedDistrictId != null && selectedDistrictId!.isNotEmpty) {
        params.add('districtId=$selectedDistrictId');
      }
      if (selectedWorkType != null && selectedWorkType!.isNotEmpty) {
        params.add('mainCategory=$selectedWorkType');
      }

      String queryParams = params.isNotEmpty ? '?${params.join('&')}' : '';

      final apiResponse = await ApiService.instance.post(
        endpoint:
            '${ApiConstants.baseUrl}${ApiEndpoints.getSubWorkTypeAPI}$queryParams',
        fromJson: (json) => SubWorkTypeModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess == true && apiResponse.data != null) {
        subWorkTypeList = apiResponse.data;
        _allSubWorkTypeList = subWorkTypeList?.data ?? [];
      }
    } catch (e) {
      LogService.debug('Error fetching sub work types: $e');
    } finally {
      isLoadingSubWorkTypes = false;
      notifyListeners();
    }
  }

  // Fetch all work statuses (independent)
  Future<void> fetchAllWorkStatuses(BuildContext context) async {
    if (!context.mounted) return;
    isLoadingWorkStatus = true;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoadingWorkStatus = false;
        if (context.mounted) context.go('/login');
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      // Build query params - all are optional
      List<String> params = [];

      if (selectedDivisionId != null && selectedDivisionId!.isNotEmpty) {
        params.add('divisionId=$selectedDivisionId');
      }
      if (selectedDistrictId != null && selectedDistrictId!.isNotEmpty) {
        params.add('districtId=$selectedDistrictId');
      }
      if (selectedWorkType != null && selectedWorkType!.isNotEmpty) {
        params.add('mainCategory=$selectedWorkType');
      }
      if (selectedSubWorkType != null && selectedSubWorkType!.isNotEmpty) {
        params.add('subCategory=$selectedSubWorkType');
      }

      String queryParams = params.isNotEmpty ? '?${params.join('&')}' : '';

      final apiResponse = await ApiService.instance.post(
        endpoint:
            '${ApiConstants.baseUrl}${ApiEndpoints.getWorkStatusAPI}$queryParams',
        fromJson: (json) => WorkStatusModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess == true && apiResponse.data != null) {
        workStatusList = apiResponse.data;
        _allWorkStatusList = workStatusList?.data ?? [];
      }
    } catch (e) {
      LogService.debug('Error fetching work statuses: $e');
    } finally {
      isLoadingWorkStatus = false;
      notifyListeners();
    }
  }

  // Fetch all tender numbers (independent)
  Future<void> fetchAllTenderNumbers(BuildContext context) async {
    if (!context.mounted) return;
    isLoadingTenderNumbers = true;
    notifyListeners();

    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        isLoadingTenderNumbers = false;
        if (context.mounted) context.go('/login');
        return;
      }

      ApiService.instance.setAccessToken(accessToken);

      // Build query params - all are optional
      List<String> params = [];

      if (selectedDivisionId != null && selectedDivisionId!.isNotEmpty) {
        params.add('divisionId=$selectedDivisionId');
      }
      if (selectedDistrictId != null && selectedDistrictId!.isNotEmpty) {
        params.add('districtId=$selectedDistrictId');
      }
      if (selectedWorkType != null && selectedWorkType!.isNotEmpty) {
        params.add('mainCategory=$selectedWorkType');
      }
      if (selectedSubWorkType != null && selectedSubWorkType!.isNotEmpty) {
        params.add('subCategory=$selectedSubWorkType');
      }
      if (selectedWorkStatus != null && selectedWorkStatus!.isNotEmpty) {
        params.add('workStatus=$selectedWorkStatus');
      }

      String queryParams = params.isNotEmpty ? '?${params.join('&')}' : '';

      final apiResponse = await ApiService.instance.post(
        endpoint:
            '${ApiConstants.baseUrl}${ApiEndpoints.getTenderNumber}$queryParams',
        fromJson: (json) => TenderNumberModel.fromJson(json),
      );

      if (!context.mounted) return;

      if (apiResponse.isSuccess == true && apiResponse.data != null) {
        tenderNumberList = apiResponse.data;
        _allTenderNumberList = tenderNumberList?.data ?? [];
      }
    } catch (e) {
      LogService.debug('Error fetching tender numbers: $e');
    } finally {
      isLoadingTenderNumbers = false;
      notifyListeners();
    }
  }

  // Initialize all dropdowns at once
  Future<void> initializeAllFilters(BuildContext context) async {
    await fetchAllDivisionList(context);
    // Don't fetch districts initially - they'll be fetched when division is selected
    await Future.wait([
      // ignore: use_build_context_synchronously
      fetchAllWorkTypes(context),
      // ignore: use_build_context_synchronously
      fetchAllSubWorkTypes(context),
      // ignore: use_build_context_synchronously
      fetchAllWorkStatuses(context),
      // ignore: use_build_context_synchronously
      fetchAllTenderNumbers(context),
    ]);
    _filteredDistrictList = [];
  }

  // Update or add this method for handling division selection:
  Future<void> onDivisionChanged(
    BuildContext context,
    String? divisionId,
  ) async {
    selectedDivisionId = divisionId;

    // Reset district selection
    selectedDistrict = null;
    selectedDistrictId = null;

    if (divisionId != null && divisionId.isNotEmpty) {
      // Fetch districts for the selected division
      await fetchAllDistricts(context, divisionId: divisionId);
    } else {
      // Clear districts if no division selected
      _allDistrictList = [];
      _filteredDistrictList = [];
    }

    notifyListeners();
  }

  // Add this method to FilterViewModel
  void filterDistrictsByDivision(String? divisionId) {
    // if (divisionId == null || divisionId.isEmpty) {
    //   // If no division selected, show all districts
    //   _filteredDistrictList = List.from(allDistrictList);
    // } else {
    //   // Filter districts based on selected division
    //   _filteredDistrictList = allDistrictList.where((district) {
    //     final json = district.toJson();
    //     return json['division']?.toString() == divisionId;
    //   }).toList();
    // }

    // // Reset selected district if it's not in the filtered list
    // if (selectedDistrictId != null) {
    //   final districtExists = _filteredDistrictList.any((district) {
    //     final json = district.toJson();
    //     return json['district']?.toString() == selectedDistrictId;
    //   });

    //   if (!districtExists) {
    //     selectedDistrictId = null;
    //     selectedDistrict = null;
    //   }
    // }

    notifyListeners();
  }

  // Clear all selections
  void clearAllSelections() {
    selectedDivision = null;
    selectedDivisionId = null;
    selectedDistrict = null;
    selectedDistrictId = null;
    selectedWorkType = null;
    selectedSubWorkType = null;
    selectedWorkStatus = null;
    selectedTenderNumber = null;
    selectedTenderNumberId = null;
    searchController.clear();
    notifyListeners();
  }
}
