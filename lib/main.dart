import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'common/colors.dart';
import 'common/hive_boxes.dart';
import 'common/styles.dart';
import 'database/database_helper.dart';
import 'screens/add_blood_request_screen.dart';
import 'screens/add_donation_offer_screen.dart';
import 'screens/add_news_item.dart';
import 'screens/add_organization_screen.dart';
import 'screens/add_admin_screen.dart';
import 'screens/admin_announcement_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_message_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/edit_organization_screen.dart';
import 'screens/message_audit_screen.dart';
import 'screens/organization_management_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/news_screen.dart';
import 'screens/organization_dashboard_screen.dart';
import 'screens/organization_profile_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/who_can_donate_screen.dart';
import 'screens/change_password_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await Hive.openBox(ConfigBox.key);
  
  // Initialize SQLite database
  await DatabaseHelper.instance.database;
  debugPrint('SQLite database initialized');
  // Initialize local notifications
  await NotificationService.instance.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Donation',
      theme: ThemeData(
        primarySwatch: MainColors.swatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: Fonts.text,
      ),
      initialRoute: SplashScreen.route,
      routes: {
        HomeScreen.route: (_) => const HomeScreen(),
        TutorialScreen.route: (_) => const TutorialScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        AdminLoginScreen.route: (_) => const AdminLoginScreen(),
        RegistrationScreen.route: (_) => const RegistrationScreen(),
        SplashScreen.route: (_) => const SplashScreen(),
        ProfileScreen.route: (_) => const ProfileScreen(),
        WhoCanDonateScreen.route: (_) => const WhoCanDonateScreen(),
        AddBloodRequestScreen.route: (_) => const AddBloodRequestScreen(),
        AddDonationOfferScreen.route: (_) => const AddDonationOfferScreen(),
        ChatListScreen.route: (_) => const ChatListScreen(),
        NewsScreen.route: (_) => const NewsScreen(),
        AddNewsItem.route: (_) => const AddNewsItem(),
        AddOrganizationScreen.route: (_) => const AddOrganizationScreen(),
        AddAdminScreen.route: (_) => const AddAdminScreen(),
        AdminAnnouncementScreen.route: (_) => const AdminAnnouncementScreen(),
        AdminDashboardScreen.route: (_) => const AdminDashboardScreen(),
        AdminMessageScreen.route: (_) => const AdminMessageScreen(),
        EditProfileScreen.route: (_) => const EditProfileScreen(),
        ForgotPasswordScreen.route: (_) => const ForgotPasswordScreen(),
        MessageAuditScreen.route: (_) => const MessageAuditScreen(),
        OrganizationDashboardScreen.route: (_) => const OrganizationDashboardScreen(),
        OrganizationManagementScreen.route: (_) => const OrganizationManagementScreen(),
        OrganizationProfileScreen.route: (_) => const OrganizationProfileScreen(),
        UserManagementScreen.route: (_) => const UserManagementScreen(),
        ChangePasswordScreen.route: (_) => const ChangePasswordScreen(),
      },
    );
  }
}
