import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/services/background_service.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/services/user_service.dart';
import 'core/services/task_service.dart';
import 'core/services/focus_session_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/focus_detection_service.dart';
import 'core/services/focus_state_manager.dart';
import 'core/services/gacha_service.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  }
  await NotificationService.initialize();
  await BackgroundService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => UserService()),
            ChangeNotifierProvider(create: (_) => TaskService()),
            ChangeNotifierProxyProvider<UserService, FocusSessionService>(
              create: (context) => FocusSessionService(
                Provider.of<UserService>(context, listen: false),
              ),
              update: (context, userService, previous) =>
              previous ?? FocusSessionService(userService),
            ),
            ChangeNotifierProvider(create: (_) => FocusDetectionService()),
            ChangeNotifierProxyProvider<  // Fixed: Added opening
                FocusDetectionService,
                FocusStateManager>(
              create: (context) => FocusStateManager(
                Provider.of<FocusDetectionService>(context, listen: false),
              ),
              update: (context, detection, previous) =>
              previous ?? FocusStateManager(detection),
            ),
            ChangeNotifierProvider(create: (_) => GachaService()),
          ],
          child: MaterialApp(
            title: 'Focus Hero',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.background,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
            ),
            home: const AuthWrapper(),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}