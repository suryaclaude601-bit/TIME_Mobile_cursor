import 'package:flutter/material.dart';
import 'package:streaming_dashboard/core/constants/app_asset_images.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/core/utils/connectivity_service.dart';
import 'package:streaming_dashboard/features/views/login/data_model/login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
    // Listen to loading state changes
    _viewModel.addListener(_onLoadingChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onLoadingChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onLoadingChanged() {
    if (mounted) {
      setState(() {}); // Rebuild when loading state changes
    }
  }

  // Helper to check if keyboard is visible
  bool get _isKeyboardVisible => MediaQuery.of(context).viewInsets.bottom > 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(bgImg),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  children: [
                    // Main content area
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: isTablet ? 64.0 : 32.0,
                            right: isTablet ? 64.0 : 32.0,
                            top: 24,
                            bottom: _isKeyboardVisible
                                ? 24
                                : 100, // Extra space when keyboard is hidden
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 500 : 400,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                //Logo
                                Container(
                                  width: isTablet ? 180 : 140,
                                  height: isTablet ? 180 : 140,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(appIconImg),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isTablet ? 48.0 : 32.0),

                                //Login Form
                                Container(
                                  padding: EdgeInsets.all(
                                    isTablet ? 32.0 : 24.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(24.0),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 30.0,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Username field
                                      Text(
                                        AppStrings.ksUserName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: const Color(0xFF1A237E),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              fontSize: isTablet ? 16.0 : 14.0,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.white),
                                          ],
                                        ),
                                        child: TextField(
                                          controller:
                                              _viewModel.userNameController,
                                          enabled: !_viewModel.isLoading,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 0.5,
                                                fontSize: isTablet
                                                    ? 16.0
                                                    : 14.0,
                                              ),
                                          decoration: InputDecoration(
                                            hintText: AppStrings.ksUserName,
                                            hintStyle: TextStyle(
                                              fontSize: isTablet ? 16.0 : 14.0,
                                              color: Colors.grey.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: isTablet
                                                      ? 16.0
                                                      : 12.0,
                                                  horizontal: 16.0,
                                                ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isTablet ? 24.0 : 16.0),

                                      // Password field
                                      Text(
                                        AppStrings.ksPassword,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: const Color(0xFF1A237E),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              fontSize: isTablet ? 16.0 : 14.0,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.white),
                                          ],
                                        ),
                                        child: TextField(
                                          controller:
                                              _viewModel.passwordController,
                                          obscureText:
                                              _viewModel.obscurePassword,
                                          enabled: !_viewModel.isLoading,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 0.5,
                                                fontSize: isTablet
                                                    ? 16.0
                                                    : 14.0,
                                              ),
                                          decoration: InputDecoration(
                                            hintText: AppStrings.ksPassword,
                                            hintStyle: TextStyle(
                                              fontSize: isTablet ? 16.0 : 14.0,
                                              color: Colors.grey.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: isTablet
                                                      ? 16.0
                                                      : 12.0,
                                                  horizontal: 16.0,
                                                ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _viewModel.obscurePassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.grey,
                                              ),
                                              onPressed: _viewModel.isLoading
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        _viewModel
                                                                .obscurePassword =
                                                            !_viewModel
                                                                .obscurePassword;
                                                      });
                                                    },
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isTablet ? 32.0 : 20.0),

                                      // Remember me checkbox
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _viewModel.rememberMe,
                                              onChanged: _viewModel.isLoading
                                                  ? null
                                                  : (value) {
                                                      _viewModel
                                                          .toggleRememberMe();
                                                    },
                                              activeColor: const Color(
                                                0xFF5C68C0,
                                              ),
                                              checkColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              side: BorderSide(
                                                color: const Color(
                                                  0xFF1A237E,
                                                ).withValues(alpha: 0.5),
                                                width: 2.0,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            AppStrings.ksRememberMe,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF1a237e,
                                                  ),
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.3,
                                                  fontSize: isTablet ? 14 : 13,
                                                ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: isTablet ? 24.0 : 20.0),

                                      // Sign In button
                                      SizedBox(
                                        width: double.infinity,
                                        height: isTablet ? 56.0 : 52.0,
                                        child: ElevatedButton(
                                          onPressed: _viewModel.isLoading
                                              ? null
                                              : () {
                                                  _viewModel.submitForm(
                                                    context,
                                                  );
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF5C68C0,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 5.0,
                                            shadowColor: Colors.black
                                                .withValues(alpha: 0.3),
                                            disabledBackgroundColor:
                                                const Color(
                                                  0xFF5C68C0,
                                                ).withValues(alpha: 0.6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: Text(
                                            AppStrings.ksSignIn,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.3,
                                                  fontSize: isTablet
                                                      ? 20.0
                                                      : 16.0,
                                                ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isTablet ? 32.0 : 30.0),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Footer at bottom - hides when keyboard is visible
                    if (!_isKeyboardVisible)
                      AnimatedOpacity(
                        opacity: _isKeyboardVisible ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30.0),
                          child: Text(
                            AppStrings.ksCopyRight,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                  fontSize: isTablet ? 14.0 : 12.0,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Full screen loader overlay
              if (_viewModel.isLoading)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20.0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 3.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF5C68C0),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            AppStrings.ksSigningIn,
                            style: TextStyle(
                              fontSize: isTablet ? 16.0 : 14.0,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
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
