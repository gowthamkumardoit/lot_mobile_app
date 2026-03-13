import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:mobile_app/screens/auth/auth_gate.dart';
import 'package:mobile_app/screens/maintenance/maintanance_page.dart';
import 'package:mobile_app/screens/splash/splash_screen.dart';
import 'package:mobile_app/services/platform_config_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/services/push_notification_service.dart';
import 'package:flutter/foundation.dart';
/// ✅ REQUIRED for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ✅ BACKGROUND HANDLER (MUST BE TOP-LEVEL)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ SET STATUS BAR STYLE GLOBALLY
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Android
      statusBarBrightness: Brightness.light, // iOS
    ),
  );

  await Firebase.initializeApp();

  // 🔥 THIS WAS REMOVED — ADD IT BACK
  await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode
      ? AndroidProvider.debug
      : AndroidProvider.playIntegrity,
);

  // ✅ ONLY safe thing in main()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      PushNotificationService.init();
    }
  });

  runApp(const MyApp());
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _platformConfigFailed = false;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPlatformConfig();
  }

  Future<void> _loadPlatformConfig() async {
    try {
      await PlatformConfigService.load();
      print("✅ Platform config loaded successfully");
    } catch (e, stack) {
      print("❌ Platform config failed: $e");
      print(stack);
      _platformConfigFailed = true;
    } finally {
      if (mounted) {
        setState(() => _configLoaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,

      // ✅ REGISTER YOUR THEME HERE
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      builder: (context, child) {
        // ⏳ Still loading config
        if (!_configLoaded) {
          return const SplashScreen();
        }

        // ❌ Failed to load config
        if (_platformConfigFailed) {
          return const MaintenancePage();
        }

        final config = PlatformConfigService.current;

        // 🚧 Maintenance mode
        if (config.maintenanceMode) {
          return const MaintenancePage();
        }

        return child!;
      },

      // 🏠 Home must also wait for config
      home: !_configLoaded
          ? const SplashScreen()
          : _platformConfigFailed
          ? const MaintenancePage()
          : FirebaseAuth.instance.currentUser == null
          ? const SplashScreen()
          : const AuthGate(),
    );
  }
}
