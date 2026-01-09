import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streaming_dashboard/core/constants/app_asset_images.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/core/theme/app_themes.dart';
import 'package:streaming_dashboard/core/theme/theme_provider.dart';
import 'package:streaming_dashboard/features/views/dashboard/presentation/home_view.dart';
import 'package:streaming_dashboard/features/views/profile/data_model/profile_view_model.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with WidgetsBindingObserver {
  late ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchUserInfo(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildHeader(constraints, isDarkMode),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProfileContent(constraints, isDarkMode),
                        _buildProfileElements(constraints, isDarkMode),
                      ],
                    ),
                  ),
                ),
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

  Widget _buildHeader(BoxConstraints constraints, bool isDarkMode) {
    final deviceType = _getDeviceType(constraints);
    final isLargeScreen = deviceType == DeviceType.ipad;
    final isTablet = deviceType == DeviceType.tablet;

    return Container(
      height: isLargeScreen
          ? 60.0
          : isTablet
          ? 60
          : 50,
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen
            ? 24.0
            : isTablet
            ? 20.0
            : 16.0,
      ),
      width: constraints.maxWidth,
      color: AppThemes.getSurfaceColor(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.ksProfile,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppThemes.getTextColor(context),
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              // Theme Toggle Icon Button
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return IconButton(
                    onPressed: () {
                      themeProvider.toggleTheme();
                    }, // ✅ Single handler

                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        key: ValueKey<bool>(themeProvider.isDarkMode),
                        color: AppThemes.getTextColor(context),
                        size: isLargeScreen ? 28 : 24,
                      ),
                    ),

                    tooltip: themeProvider.isDarkMode
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                  );
                },
              ),
              SizedBox(width: isLargeScreen ? 4 : 0),
              // Logout Icon Button
              IconButton(
                icon: Icon(
                  Icons.logout,
                  color: AppThemes.getTextColor(context),
                  size: isLargeScreen ? 28 : 24,
                ),
                onPressed: () {
                  Theme.of(context).platform == TargetPlatform.iOS
                      ? _viewModel.showiOSAlertDialog(context)
                      : _viewModel.showAndroidAlertDialog(context);
                },
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BoxConstraints constraints, bool isDarkMode) {
    final deviceType = _getDeviceType(constraints);
    final isLargeScreen = deviceType == DeviceType.ipad;
    final isTablet = deviceType == DeviceType.tablet;

    final avatarRadius = isLargeScreen
        ? 70.0
        : isTablet
        ? 60.0
        : 50.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isLargeScreen
            ? 30.0
            : isTablet
            ? 24.0
            : 20.0,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundImage: Image.asset(userImg).image,
          ),
          SizedBox(
            height: isLargeScreen
                ? 16
                : isTablet
                ? 12
                : 8,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileElements(BoxConstraints constraints, bool isDarkMode) {
    final deviceType = _getDeviceType(constraints);
    final isLargeScreen = deviceType == DeviceType.ipad;
    final isTablet = deviceType == DeviceType.tablet;

    final fieldHeight = isTablet ? 45.0 : 40.0;
    final fontSize = isTablet ? 17.0 : 14.0;
    final labelFontSize = isTablet ? 16.0 : 14.0;
    final spacing = isTablet ? 16.0 : 15.0;
    final horizontalPadding = isTablet ? 32.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isLargeScreen
            ? 24.0
            : isTablet
            ? 20.0
            : 16.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTextFieldCommon(
            label: AppStrings.ksFirstName,
            controller: _viewModel.firstNameController,
            required: true,
            hint: '',
            keyboardType: TextInputType.text,
            height: fieldHeight,
            fontSize: fontSize,
            labelFontSize: labelFontSize,
            enabled: false,
            isDarkMode: isDarkMode,
            context: context,
          ),
          SizedBox(height: spacing),
          buildTextFieldCommon(
            label: AppStrings.ksLastName,
            controller: _viewModel.lastNameController,
            required: true,
            hint: '',
            keyboardType: TextInputType.text,
            height: fieldHeight,
            fontSize: fontSize,
            labelFontSize: labelFontSize,
            enabled: false,
            isDarkMode: isDarkMode,
            context: context,
          ),
          SizedBox(height: spacing),
          buildTextFieldCommon(
            label: AppStrings.ksEmail,
            controller: _viewModel.emailController,
            required: true,
            hint: '',
            keyboardType: TextInputType.emailAddress,
            height: fieldHeight,
            fontSize: fontSize,
            labelFontSize: labelFontSize,
            enabled: false,
            isDarkMode: isDarkMode,
            context: context,
          ),
          SizedBox(height: spacing),
          buildTextFieldCommon(
            label: AppStrings.ksPhoneNumber,
            controller: _viewModel.phoneController,
            required: true,
            hint: '',
            keyboardType: TextInputType.phone,
            height: fieldHeight,
            fontSize: fontSize,
            labelFontSize: labelFontSize,
            enabled: false,
            isDarkMode: isDarkMode,
            context: context,
          ),
          SizedBox(height: spacing),
          buildTextFieldCommon(
            label: AppStrings.ksUserGroupName,
            controller: _viewModel.userGroupController,
            required: true,
            hint: '',
            keyboardType: TextInputType.text,
            height: fieldHeight,
            fontSize: fontSize,
            labelFontSize: labelFontSize,
            enabled: false,
            isDarkMode: isDarkMode,
            context: context,
          ),
          SizedBox(height: spacing),
          buildTextFieldCommon(
            label: AppStrings.ksRoleName,
            controller: _viewModel.roleNameController,
            required: true,
            hint: '',
            keyboardType: TextInputType.text,
            height: fieldHeight,
            fontSize: fontSize,
            labelFontSize: labelFontSize,
            enabled: false,
            isDarkMode: isDarkMode,
            context: context,
          ),
          SizedBox(height: spacing),
        ],
      ),
    );
  }
}

Widget buildTextFieldCommon({
  required BuildContext context,
  required String label,
  required TextEditingController controller,
  required bool required,
  required String hint,
  required double height,
  required double fontSize,
  required double labelFontSize,
  required bool isDarkMode,
  bool enabled = true,
  TextInputType? keyboardType,
  FocusNode? focusNode,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppThemes.getTextColor(context),
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (required)
            Text(
              ' *',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        height: height,
        decoration: BoxDecoration(
          color: enabled
              ? (isDarkMode ? Colors.white : Colors.white)
              : AppThemes.getSurfaceColor(context),
          border: Border.all(
            color: enabled
                ? (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade300)
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            readOnly: !enabled,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: enabled
                  ? Colors.black87
                  : (isDarkMode ? Colors.white70 : Colors.black54),
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: fontSize,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
              filled: false,
            ),
            validator:
                validator ??
                (required
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      }
                    : null),
          ),
        ),
      ),
    ],
  );
}
