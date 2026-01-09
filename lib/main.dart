import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streaming_dashboard/app/app.dart';
import 'package:streaming_dashboard/core/theme/theme_provider.dart';
import 'package:streaming_dashboard/core/utils/connectivity_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ConnectivityService().initialize();
  // Initialize MediaKit if needed
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => ThemeProvider())],
      child: const MyApp(),
    ),
  );
}
