import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:streaming_dashboard/core/config/shared_preferences/shared_preference_service.dart';
import 'package:streaming_dashboard/core/constants/app_asset_images.dart';
import 'package:streaming_dashboard/features/views/splash/data_model/splash_view_model.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late SplashViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = SplashViewModel();

    // Fixed: Changed duration from 10ms to 2000ms (2 seconds)
    viewModel.animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    viewModel.animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: viewModel.animationController!,
        curve: Curves.easeInOut,
      ),
    );

    viewModel.animationController!.forward();

    viewModel.animationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Added slight delay before navigation for better UX
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (mounted) {
            final prefService = await SharedPreferenceService.getInstance();
            final loginStatus = prefService.getLoginStatus();
            if (loginStatus) {
              // ignore: use_build_context_synchronously
              context.go('/maintabbar');
            } else {
              // ignore: use_build_context_synchronously
              context.go('/login');
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    viewModel.animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: viewModel.animationController!,
          builder: (context, child) {
            return Opacity(
              opacity: viewModel.animation!.value,
              child: Transform.scale(
                scale: viewModel.animation!.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Image.asset(
                    appIconImg,
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.width * 0.5,
                    // Added error handling
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.width * 0.5,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
