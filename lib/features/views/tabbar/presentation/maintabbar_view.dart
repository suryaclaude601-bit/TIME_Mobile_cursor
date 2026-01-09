import 'package:flutter/material.dart';
import 'package:streaming_dashboard/core/constants/app_asset_images.dart';
import 'package:streaming_dashboard/core/theme/app_themes.dart';
import 'package:streaming_dashboard/features/views/dashboard/presentation/home_view.dart';
import 'package:streaming_dashboard/features/views/profile/presentation/profile_view.dart';
import 'package:streaming_dashboard/features/views/search/presentation/search_view.dart';
import '../../camera/presentation/camera_page.dart';

class MaintabbarView extends StatefulWidget {
  const MaintabbarView({super.key});

  @override
  State<MaintabbarView> createState() => _MaintabbarViewState();
}

class _MaintabbarViewState extends State<MaintabbarView> {
  int _selectedIndex = 0;

  // List of pages/classes for each tab
  final List<Widget> _pages = [
    const HomeView(),
    const CameraView(),
    const SearchView(),
    const ProfileView(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final bool isTablet = shortestSide >= 600;

    // Check if current theme is dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors based on theme
    final bottomBarColor = isDarkMode
        ? const Color(0xFF2a2a2a) // Dark mode color
        : Colors.white; // Light mode color

    final shadowColor = isDarkMode
        ? Colors.black26
        : Colors.grey.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      body: _pages[_selectedIndex], // Display selected page
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomBarColor,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: isTablet ? 80 : 60,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 20,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(
                  index: 0,
                  assetPath: homeImg,
                  isTablet: isTablet,
                  isDarkMode: isDarkMode,
                ),
                _buildTabItem(
                  index: 1,
                  assetPath: cameraImg,
                  isTablet: isTablet,
                  isDarkMode: isDarkMode,
                ),
                _buildTabItem(
                  index: 2,
                  assetPath: searchImg,
                  isTablet: isTablet,
                  isDarkMode: isDarkMode,
                ),
                _buildTabItem(
                  index: 3,
                  assetPath: menuImg,
                  isTablet: isTablet,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String assetPath,
    required bool isTablet,
    required bool isDarkMode,
  }) {
    final isSelected = _selectedIndex == index;

    // Define colors based on theme and selection state
    final selectedBgColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.blue.withValues(alpha: 0.1);

    final selectedBorderColor = isDarkMode
        ? const Color(0xFFB1B2B2)
        : Colors.blue;

    final selectedIconColor = isDarkMode ? Colors.white : Colors.blue;

    final unselectedIconColor = isDarkMode ? Colors.grey : Colors.grey.shade600;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 18 : 14,
              vertical: isTablet ? 12 : 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? selectedBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: isSelected
                  ? Border.all(color: selectedBorderColor, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Image.asset(
              assetPath,
              color: isSelected ? selectedIconColor : unselectedIconColor,
              width: isTablet ? 32.0 : 24.0,
              height: isTablet ? 32.0 : 24.0,
            ),
          ),
        ],
      ),
    );
  }
}
