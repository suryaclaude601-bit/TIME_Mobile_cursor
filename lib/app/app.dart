import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:streaming_dashboard/app/routers.dart';
import 'package:streaming_dashboard/core/config/toast_service/toast_service.dart';
import 'package:streaming_dashboard/core/theme/app_themes.dart';
import 'package:streaming_dashboard/core/theme/theme_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widgets is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 756),
      minTextAdapt: true,
      splitScreenMode: true,

      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: MaterialApp.router(
              scaffoldMessengerKey: ToastService.scaffoldKey,
              debugShowCheckedModeBanner: false,
              title: '',
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: appRouter,
            ),
          );
        },
      ),
    );
  }
}
