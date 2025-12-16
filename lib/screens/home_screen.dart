import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../database/user_session.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/users_list.dart';
import 'admin_dashboard_screen.dart';
import 'organization_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  static const route = 'home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await UserSession.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
    
    // Redirect organizations to their dashboard
    // Admins should not see the home screen (they manage the system, not participate)
    if (user != null) {
      final userRole = user['user_role'] as String? ?? 'donor';
      final isAdmin = user['is_admin'] == true;
      
      if (userRole == 'organization' && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(OrganizationDashboardScreen.route);
        });
      } else if (isAdmin && mounted) {
        // Redirect admins to admin dashboard
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AdminDashboardScreen.route);
        });
      }
    }
  }

  String _getTitle() {
    final userRole = _currentUser?['user_role'] as String? ?? 'donor';
    if (userRole == 'donor') {
      return 'Available Recipients';
    } else {
      return 'Available Donors';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?['is_admin'] == true;
    
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(title: const Text('Blood Donation System')),
      body: SafeArea(
        child: isAdmin
            ? _buildAdminView()
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                IconAssets.bloodBagHand,
                                height: 80,
                                width: 80,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Donate Blood,\nSave Lives',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .copyWith(color: MainColors.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverAppBar(
                    title: Text(
                      _getTitle(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: MainColors.primary),
                    ),
                    primary: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    automaticallyImplyLeading: false,
                  ),
                  const UsersList(),
                ],
              ),
      ),
    );
  }

  Widget _buildAdminView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: MainColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'System Administration',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: MainColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'You are logged in as a system administrator.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Use the menu to manage organizations, admins, and news.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Admin Features',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(Icons.business, 'Add Organizations'),
                    _buildFeatureItem(Icons.admin_panel_settings, 'Add Admins'),
                    _buildFeatureItem(Icons.article, 'Add News'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: MainColors.primary),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
