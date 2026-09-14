import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/sign_in_screen.dart';

void main() {
  runApp(const OurWatchApp());
}

class OurWatchApp extends StatelessWidget {
  const OurWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OurWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryRed,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryRed,
          surface: AppColors.cardBg,
        ),
      ),
      home: const SignInScreen(),
    );
  }
}