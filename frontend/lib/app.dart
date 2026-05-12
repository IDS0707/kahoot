import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/auth/presentation/login_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Root widget. Picks up theme + sets system UI overlay.
class KahootApp extends StatelessWidget {
  const KahootApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.bgDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Present Perfect Quiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) {
        // Clamp text scale so accessibility settings can't break the layout.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LoginScreen(),
    );
  }
}
