import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';

import '../common/assets.dart';
import '../common/hive_boxes.dart';
import '../common/styles.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'organization_dashboard_screen.dart';
import 'tutorial_screen.dart';

class SplashScreen extends StatefulWidget {
  static const route = '/';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for the first frame to ensure the context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveDestination();
    });
  }

  Future<void> _resolveDestination() async {
    // Allows the splash screen to remain for a bit longer
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) {
      debugPrint('SplashScreen: Widget not mounted, skipping navigation');
      return;
    }

    try {
      final isFirstLaunch = Hive.box(ConfigBox.key)
          .get(ConfigBox.isFirstLaunch, defaultValue: true) as bool;
      debugPrint('SplashScreen: isFirstLaunch = $isFirstLaunch');

      String destination;
      if (isFirstLaunch) {
        destination = TutorialScreen.route;
        debugPrint('SplashScreen: Navigating to tutorial screen');
      } else {
        // Check local SQLite session
        final userId = UserSession.getCurrentUserId();
        if (userId != null) {
          // Verify user still exists in database
          final user = await DatabaseHelper.instance.getUserById(userId);
          if (user != null) {
            debugPrint('SplashScreen: Found logged in user: ${user['email']}');
            final userRole = user['user_role'] as String? ?? 'donor';
            destination = userRole == 'organization' 
                ? OrganizationDashboardScreen.route 
                : HomeScreen.route;
            _updateCachedData(user);
          } else {
            debugPrint('SplashScreen: User not found, navigating to login screen');
            await UserSession.clearSession();
            destination = LoginScreen.route;
          }
        } else {
          debugPrint('SplashScreen: No logged in user, navigating to login screen');
          destination = LoginScreen.route;
        }
      }

      if (mounted) {
        debugPrint('SplashScreen: Attempting navigation to: $destination');
        Navigator.of(context).pushReplacementNamed(destination);
        debugPrint('SplashScreen: Navigation completed');
      } else {
        debugPrint('SplashScreen: Widget unmounted before navigation');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _resolveDestination: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        debugPrint('SplashScreen: Fallback navigation to login screen');
        Navigator.of(context).pushReplacementNamed(LoginScreen.route);
      }
    }
  }

  Future<void> _updateCachedData(Map<String, dynamic> user) async {
    final configBox = Hive.box(ConfigBox.key);
    configBox.put(ConfigBox.bloodType, user['blood_type'] as String);
    configBox.put(ConfigBox.isAdmin, user['is_admin'] as bool);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(IconAssets.logo),
              const SizedBox(height: 28),
              Flexible(
                child: Text(
                  'Blood Donation',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontFamily: Fonts.logo,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
