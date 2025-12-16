import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

import '../common/app_config.dart';
import '../common/assets.dart';
import '../common/colors.dart';
import '../common/hive_boxes.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../widgets/profile_image.dart';
import '../screens/add_blood_request_screen.dart';
import '../screens/add_donation_offer_screen.dart';
import '../screens/add_news_item.dart';
import '../screens/add_organization_screen.dart';
import '../screens/add_admin_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/news_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/who_can_donate_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/organization_dashboard_screen.dart';
import '../screens/change_password_screen.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _showAdmin = false;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserSession.getCurrentUser();
    setState(() {
      _user = user;
      _showAdmin = user?['is_admin'] == true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_user?['name'] ?? 'Blood Donation'),
              accountEmail: Text(_user?['email'] ?? AppConfig.email),
              otherAccountsPictures: [
                if (_user?['is_admin'] == true)
                  InkWell(
                    onTap: () {
                      setState(() => _showAdmin = !_showAdmin);
                    },
                    child: const Tooltip(
                      message: 'Admin Screens',
                      child: CircleAvatar(child: Icon(FontAwesomeIcons.userSecret)),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    AwesomeDialog(
                      context: context,
                      headerAnimationLoop: false,
                      dialogType: DialogType.question,
                      title: 'Logout',
                      desc: 'Are you sure you want to logout?',
                      btnCancelText: 'NO',
                      btnCancelOnPress: () {},
                      btnOkText: 'YES',
                      btnOkOnPress: () async {
                        // Clear local session
                        await UserSession.clearSession();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          LoginScreen.route,
                          (route) => false,
                        );
                      },
                    ).show();
                  },
                    child: const Tooltip(
                      message: 'Logout',
                      child: CircleAvatar(child: Icon(FontAwesomeIcons.lockOpen)),
                    ),
                ),
              ],
              currentAccountPicture: Hero(
                tag: 'profilePicHero',
                child: Container(
                  decoration: const BoxDecoration(
                    color: MainColors.accent,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ProfileImage(
                    imagePath: _user?['profile_image_url'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              margin: EdgeInsets.zero,
            ),
            Expanded(child: Column(children: _screens)),
          ],
        ),
      ),
    );
  }

  List<Widget> get _screens {
    final userRole = _user?['user_role'] as String? ?? 'donor';
    final isDonor = userRole == 'donor';
    final isRecipient = userRole == 'recipient';
    final isOrganization = userRole == 'organization';
    final organizationType = _user?['organization_type'] as String?;
    final isAdmin = (_user?['is_admin'] as bool?) ?? false; // Admin is determined by is_admin flag
    
    return [
      if (isOrganization)
        _DrawerTile(
          title: 'Dashboard',
          icon: FontAwesomeIcons.chartLine,
          destination: OrganizationDashboardScreen.route,
        ),
      const _DrawerTile(
        title: 'Profile',
        icon: FontAwesomeIcons.user,
        destination: ProfileScreen.route,
      ),
      _DrawerTile(
        title: 'Change Password',
        icon: FontAwesomeIcons.key,
        destination: ChangePasswordScreen.route,
      ),
      // Only show Messages for donors and recipients (not admins or organizations)
      if (!isOrganization && !isAdmin)
        _DrawerTileWithBadge(
          title: 'Messages',
          icon: FontAwesomeIcons.message,
          destination: ChatListScreen.route,
        ),
      // Show "Request Blood" for recipients and hospital organizations (not admins)
      if (!isAdmin && (isRecipient || (isOrganization && organizationType == 'hospital')))
        _DrawerTile(
          title: 'Request Blood',
          icon: FontAwesomeIcons.droplet,
          destination: AddBloodRequestScreen.route,
        ),
      // Only show "Offer to Donate" for donors (not admins or recipients)
      if (isDonor && !isAdmin)
        _DrawerTile(
          title: 'Offer to Donate',
          icon: FontAwesomeIcons.handHoldingHeart,
          destination: AddDonationOfferScreen.route,
        ),
      // Admin-only features
      if (isAdmin) ...[
        _DrawerTile(
          title: 'Admin Dashboard',
          icon: FontAwesomeIcons.chartLine,
          destination: AdminDashboardScreen.route,
        ),
        _DrawerTile(
          title: 'Add Organization',
          icon: FontAwesomeIcons.building,
          destination: AddOrganizationScreen.route,
        ),
        _DrawerTile(
          title: 'Add News',
          icon: FontAwesomeIcons.plus,
          destination: AddNewsItem.route,
        ),
      ],
      const _DrawerTile(
        title: 'News and Tips',
        icon: FontAwesomeIcons.bell,
        destination: NewsScreen.route,
      ),
      // Only show "Can I donate blood?" for donors and recipients (not admins or organizations)
      if (!isOrganization && !isAdmin)
        const _DrawerTile(
          title: 'Can I donate blood?',
          icon: FontAwesomeIcons.circleQuestion,
          destination: WhoCanDonateScreen.route,
        ),
    ];
  }
}

class _DrawerTile extends StatelessWidget {
  final String title, destination;
  final IconData icon;

  const _DrawerTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.destination,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).pushNamed(destination);
      },
    );
  }
}

class _DrawerTileWithBadge extends StatefulWidget {
  final String title, destination;
  final IconData icon;

  const _DrawerTileWithBadge({
    Key? key,
    required this.title,
    required this.icon,
    required this.destination,
  }) : super(key: key);

  @override
  _DrawerTileWithBadgeState createState() => _DrawerTileWithBadgeState();
}

class _DrawerTileWithBadgeState extends State<_DrawerTileWithBadge> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _startPolling();
  }

  Future<void> _loadUnreadCount() async {
    final userId = UserSession.getCurrentUserId();
    if (userId == null) return;

    try {
      final count = await DatabaseHelper.instance.getUnreadMessageCount(userId);
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadUnreadCount();
        _startPolling();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      leading: Stack(
        children: [
          Icon(widget.icon),
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).pushNamed(widget.destination);
      },
    );
  }
}
