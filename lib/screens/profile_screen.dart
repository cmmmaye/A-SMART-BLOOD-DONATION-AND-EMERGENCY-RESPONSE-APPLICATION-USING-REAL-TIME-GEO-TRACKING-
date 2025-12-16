import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/hive_boxes.dart';
import '../database/user_session.dart';
import '../utils/blood_types.dart';
import '../widgets/profile_image.dart';
import '../widgets/submitted_blood_requests.dart';
import '../widgets/submitted_donation_offers.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const route = 'profile';
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if ((_user?['user_role'] as String? ?? 'donor') != 'organization')
            IconButton(
              icon: const Icon(FontAwesomeIcons.pencil),
              onPressed: () {
                Navigator.pushReplacementNamed(context, EditProfileScreen.route);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final userRole = _user?['user_role'] as String? ?? 'donor';
            final isAdmin = (_user?['is_admin'] as bool?) ?? false;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerImage(_user?['profile_image_url']),
                _infoRow(context, _user),
                // Show "Active Blood Requests" for recipients
                if (!isAdmin && userRole == 'recipient') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
                    child: Text(
                      'Active Blood Requests:',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: MainColors.primary),
                    ),
                  ),
                  const Expanded(child: SubmittedBloodRequests()),
                ] 
                // Show "My Donation Offers" for donors
                else if (!isAdmin && userRole == 'donor') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
                    child: Text(
                      'My Donation Offers:',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: MainColors.primary),
                    ),
                  ),
                  const Expanded(child: SubmittedDonationOffers()),
                ] 
                else if (isAdmin)
                  // For admins, show a message
                  const Expanded(
                    child: Center(
                      child: Text(
                        'System Administrator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else if (userRole == 'organization')
                  // For organizations, show organization details
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      children: [
                        _organizationDetailsCard(context, _user),
                      ],
                    ),
                  )
                else
                  // For donors, show empty state
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No active requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, Map<String, dynamic>? user) {
    final isAdmin = (user?['is_admin'] as bool?) ?? false;
    final userRole = user?['user_role'] as String? ?? 'donor';
    final isOrganization = userRole == 'organization';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Only show blood type icons for donors and recipients (not admins or organizations)
          if (!isAdmin && !isOrganization) _bloodIcon(),
          Expanded(
            child: Column(
              children: [
                Text(
                  user?['name'] ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(user?['email'] ?? '', textAlign: TextAlign.center),
                // Show role badge for donors and recipients, organization type for organizations
                if (!isAdmin && !isOrganization) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: MainColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MainColors.primary),
                    ),
                    child: Text(
                      userRole == 'donor' ? 'Donor' : 'Recipient',
                      style: TextStyle(
                        color: MainColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ] else if (isOrganization) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      _getOrganizationTypeName(user?['organization_type'] as String?),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Only show blood type icons for donors and recipients (not admins or organizations)
          if (!isAdmin && !isOrganization) _bloodIcon(),
        ],
      ),
    );
  }
  
  Widget _organizationDetailsCard(BuildContext context, Map<String, dynamic>? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(FontAwesomeIcons.building, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getOrganizationTypeName(user?['organization_type'] as String?),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(user?['phone_number'] ?? 'Not provided')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(user?['location'] ?? 'Not provided')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(user?['email'] ?? '')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'These details are managed by the administrator.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  String _getOrganizationTypeName(String? type) {
    switch (type) {
      case 'hospital':
        return 'Hospital';
      case 'red_cross':
        return 'Red Cross';
      case 'blood_bank':
        return 'Blood Bank';
      default:
        return 'Organization';
    }
  }

  Widget _bloodIcon() {
    final bloodType = Hive.box(ConfigBox.key)
        .get(ConfigBox.bloodType, defaultValue: BloodType.aPos.name) as String;
    return SvgPicture.asset(
      BloodTypeUtils.fromName(bloodType).icon,
      height: 50,
    );
  }

  Widget _headerImage(String? url) => Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: curveHeight,
            child: CustomPaint(painter: _MyPainter()),
          ),
          Hero(
            tag: 'profilePicHero',
            child: Container(
              width: avatarDiameter,
              height: avatarDiameter,
              decoration: const BoxDecoration(
                color: MainColors.accent,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: ProfileImage(
                imagePath: url,
                width: avatarDiameter,
                height: avatarDiameter,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
}

const avatarRadius = 60.0;
const avatarDiameter = avatarRadius * 2;
const curveHeight = avatarRadius * 2.5;

/// Source: https://gist.github.com/tarek360/c94a82f9554caf8f6b62c4fcf140272f
class _MyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = MainColors.primary;

    const topLeft = Offset(0, 0);
    final bottomLeft = Offset(0, size.height * 0.25);
    final topRight = Offset(size.width, 0);
    final bottomRight = Offset(size.width, size.height * 0.25);

    final leftCurveControlPoint =
        Offset(size.width * 0.2, size.height - avatarRadius * 0.8);
    final rightCurveControlPoint = Offset(size.width - leftCurveControlPoint.dx,
        size.height - avatarRadius * 0.8);

    final avatarLeftPoint =
        Offset(size.width * 0.5 - avatarRadius + 5, size.height * 0.5);
    final avatarRightPoint =
        Offset(size.width * 0.5 + avatarRadius - 5, avatarLeftPoint.dy);

    final avatarTopPoint =
        Offset(size.width / 2, size.height / 2 - avatarRadius);

    final path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..quadraticBezierTo(leftCurveControlPoint.dx, leftCurveControlPoint.dy,
          avatarLeftPoint.dx, avatarLeftPoint.dy)
      ..arcToPoint(avatarTopPoint, radius: const Radius.circular(avatarRadius))
      ..lineTo(size.width / 2, 0)
      ..close();

    final path2 = Path()
      ..moveTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..quadraticBezierTo(rightCurveControlPoint.dx, rightCurveControlPoint.dy,
          avatarRightPoint.dx, avatarRightPoint.dy)
      ..arcToPoint(avatarTopPoint,
          radius: const Radius.circular(avatarRadius), clockwise: false)
      ..lineTo(size.width / 2, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
