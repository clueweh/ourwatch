import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'screens/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const OurWatchApp());
}

class OurWatchApp extends StatelessWidget {
  const OurWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.isDarkMode,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          title: 'OurWatch',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF4F5F7),
            primaryColor: AppColors.primaryRed,
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              surface: Color(0xFFFFFFFF),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0D0E11),
            primaryColor: AppColors.primaryRed,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryRed,
              surface: Color(0xFF16181D),
            ),
          ),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SignInScreen(),
        );
      },
    );
  }
}