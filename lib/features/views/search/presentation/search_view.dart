import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:streaming_dashboard/core/config/toast_service/toast_service.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/core/theme/app_themes.dart';
import 'package:streaming_dashboard/features/views/dashboard/data_model/home_view_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/model/camera_live_model.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late HomeViewModel _viewModel;

  List<CameraData> _filteredCameras = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _searchFocusNode.requestFocus();
    _loadCameraData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCameraData() async {
    try {
      await _viewModel.fetchCameraData('Report', context);
    } catch (e) {
      ToastService.showError('Failed to load camera data');
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _hasSearched = false;
        _filteredCameras = [];
      });
    } else {
      // Auto-search as user types
      _performSearch();
    }
  }

  void _performSearch() {
    if (!mounted) return;

    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _filteredCameras = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      setState(() {
        List<CameraData> cameras = _viewModel.cameraData?.data ?? [];

        final searchQuery = query.toLowerCase();
        cameras = cameras.where((camera) {
          return (camera.districtName?.toLowerCase().contains(searchQuery) ??
                  false) ||
              (camera.districtIds?.toString().contains(searchQuery) ?? false) ||
              (camera.divisionName?.toLowerCase().contains(searchQuery) ??
                  false) ||
              (camera.divisionIds?.toString().contains(searchQuery) ?? false) ||
              (camera.workStatus?.toLowerCase().contains(searchQuery) ??
                  false) ||
              (camera.tenderNumber?.toLowerCase().contains(searchQuery) ??
                  false) ||
              (camera.tenderId?.toString().contains(searchQuery) ?? false) ||
              (camera.channel?.toLowerCase().contains(searchQuery) ?? false) ||
              (camera.mainCategory?.toLowerCase().contains(searchQuery) ??
                  false) ||
              (camera.subcategory?.toLowerCase().contains(searchQuery) ??
                  false);
        }).toList();

        _filteredCameras = cameras;
        _isLoading = false;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearched = false;
      _filteredCameras = [];
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),

      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(isDark),
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return SizedBox(
      height: 75,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        // color: AppThemes.getSurfaceColor(context),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: AppThemes.getTextColor(context),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.ksSearchByAll,
                  hintStyle: TextStyle(
                    color: AppThemes.getTextColor(
                      context,
                    ).withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppThemes.getTextColor(
                      context,
                    ).withValues(alpha: 0.7),
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppThemes.getTextColor(context),
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppThemes.getTextColor(
                        context,
                      ).withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppThemes.getTextColor(
                        context,
                      ).withValues(alpha: 0.2),
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
                    vertical: 14,
                  ),
                ),
                onSubmitted: (value) => _performSearch(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (!_hasSearched) {
      return _buildInitialState(isDark);
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }

    return Column(
      children: [
        // _buildResultsCount(isDark),
        Expanded(child: _buildCameraList(isDark)),
      ],
    );
  }

  Widget _buildInitialState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              color: AppThemes.getTextColor(context).withValues(alpha: 0.3),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Search for Cameras',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppThemes.getTextColor(context).withValues(alpha: 0.7),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter district, division, tender number, or status to find cameras',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemes.getTextColor(context).withValues(alpha: 0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraList(bool isDark) {
    if (_filteredCameras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                color: AppThemes.getTextColor(context).withValues(alpha: 0.3),
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.ksNoCameraFound,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemes.getTextColor(context).withValues(alpha: 0.6),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.ksTryDifferentTerm,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppThemes.getTextColor(context).withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCameras.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final camera = _filteredCameras[index];
        return _buildCameraCard(camera, isDark);
      },
    );
  }

  Widget _buildCameraCard(CameraData camera, bool isDark) {
    final hasVideo = camera.rtspUrl != null && camera.rtspUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 4), // Reduced from 12
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
          if (!hasVideo) {
            ToastService.showError(AppStrings.ksVideoURLNotAvailable);
            return;
          }
          context.push('/live_camera', extra: camera);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
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
                  const SizedBox(width: 6),
                  _buildStatusBadge(camera.workStatus),
                ],
              ),
              const SizedBox(height: 6), // Reduced from 12
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
      case 'in-progress':
        statusColor = Colors.green;
        break;
      case 'not-started':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
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

  Widget _buildDetailRow(IconData icon, String text, bool isDark, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$type : $text',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemes.getTextColor(context).withValues(alpha: 0.75),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCameraStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      // case 'not-started':
      // case 'not started':
      //   return Colors.grey;
      // case 'in-progress':
      // case 'in progress':
      //   return Colors.orange;
      // case 'working':
      // case 'active':
      //   return Colors.green;
      // case 'maintenance':
      //   return Colors.amber;
      // case 'offline':
      // case 'not working':
      //   return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
