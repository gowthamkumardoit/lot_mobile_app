import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile_app/screens/app_shell.dart';

import 'package:mobile_app/screens/auth/auth_gate.dart';
import 'package:mobile_app/screens/maintenance/maintanance_page.dart';
import 'package:mobile_app/screens/splash/splash_screen.dart';
import 'package:mobile_app/services/platform_config_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// ✅ REQUIRED for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ✅ BACKGROUND HANDLER (MUST BE TOP-LEVEL)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // 🔥 THIS WAS REMOVED — ADD IT BACK
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // use debug first
  );

  // ✅ ONLY safe thing in main()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
      await PlatformConfigService.load().timeout(const Duration(seconds: 5));
    } catch (e) {
      _platformConfigFailed = true;
    } finally {
      if (mounted) {
        setState(() => _configLoaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ Bootstrap splash
    if (!_configLoaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        //home: SplashScreen(),
        home: MainLayout(),
      );
    }

    // 🚧 Platform maintenance / config failure
    if (_platformConfigFailed) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        //home: MaintenancePage(),
        home: MainLayout(),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final config = PlatformConfigService.current;

    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ REQUIRED
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: config.platformName,
      builder: (context, child) {
        if (config.maintenanceMode) {
          return const MaintenancePage();
        }
        return child!;
      },
      //home: user == null ? const SplashScreen() : const AuthGate(),
      home: const MainLayout(),
    );
  }
}
