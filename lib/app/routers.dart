import 'package:go_router/go_router.dart';
import 'package:streaming_dashboard/features/views/dashboard/model/camera_live_model.dart';
import 'package:streaming_dashboard/features/views/dashboard/presentation/filter_view.dart';
import 'package:streaming_dashboard/features/views/live_camera/presentation/fullscreen_video_screen.dart';
import 'package:streaming_dashboard/features/views/live_camera/view_model/video_view_model.dart';
import 'package:streaming_dashboard/features/views/login/presentation/login_view.dart';
import 'package:streaming_dashboard/features/views/splash/presentation/splash_view.dart';
import 'package:streaming_dashboard/features/views/tabbar/presentation/maintabbar_view.dart';
import '../features/views/live_camera/presentation/live_camera_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => LoginView(),
    ),

    GoRoute(
      path: '/maintabbar',
      name: 'maintabbar',
      builder: (context, statqe) {
        return const MaintabbarView();
      },
    ),
    GoRoute(
      path: '/filter',
      name: 'filter',
      builder: (context, state) {
        return const FilterView();
      },
    ),
    GoRoute(
      path: '/live_camera',
      builder: (context, state) {
        final cameraData = state.extra as CameraData;
        return LiveCameraScreen(cameraData: cameraData);
      },
    ),
    GoRoute(
      path: '/full_video_screen',
      name: 'full_video_screen',
      builder: (context, state) {
        final cameraData = state.extra as CameraViewModel;
        return VideoScreen(viewModel: cameraData);
      },
    ),
  ],
);
