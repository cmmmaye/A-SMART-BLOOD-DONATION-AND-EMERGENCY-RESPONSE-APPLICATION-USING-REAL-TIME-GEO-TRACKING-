import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../database/user_session.dart';
import '../utils/blood_types.dart';
import '../widgets/profile_image.dart';
import 'chat_screen.dart';

class ViewUserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ViewUserProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ViewUserProfileScreenState createState() => _ViewUserProfileScreenState();
}

class _ViewUserProfileScreenState extends State<ViewUserProfileScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user['name']} Profile'),
        actions: [
          // Only show chat for non-admin users viewing other users
          if (_currentUser != null && 
              _currentUser!['is_admin'] != true &&
              _currentUser!['id'] != widget.user['id'])
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(otherUser: widget.user),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showContactOptions(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerImage(widget.user['profile_image_url'] as String?),
            _infoSection(context, widget.user),
            const SizedBox(height: 24),
            _detailsSection(context, widget.user),
          ],
        ),
      ),
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
          Container(
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
        ],
      );

  Widget _infoSection(BuildContext context, Map<String, dynamic> user) {
    final userRole = user['user_role'] as String? ?? 'donor';
    final isOrganization = userRole == 'organization';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Only show blood type icons for non-organizations
          if (!isOrganization) _bloodIcon(user['blood_type'] as String),
          Expanded(
            child: Column(
              children: [
                Text(
                  user['name'] as String,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] as String,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                // Only show role badge for non-organizations, or show "Organization" for organizations
                if (!isOrganization) ...[
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
                ] else ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      _getOrganizationTypeName(user['organization_type'] as String?),
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
          // Only show blood type icons for non-organizations
          if (!isOrganization) _bloodIcon(user['blood_type'] as String),
        ],
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

  Widget _detailsSection(BuildContext context, Map<String, dynamic> user) {
    final hasPhone = user['phone_number'] != null && 
                     (user['phone_number'] as String).isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: MainColors.primary,
                ),
          ),
          const SizedBox(height: 16),
          _infoRow(
            context,
            icon: FontAwesomeIcons.envelope,
            label: 'Email',
            value: user['email'] as String,
            onTap: () async {
              await _sendEmail(context, user);
            },
          ),
          if (hasPhone) ...[
            const SizedBox(height: 12),
            _infoRow(
              context,
              icon: FontAwesomeIcons.phone,
              label: 'Phone',
              value: '+254${user['phone_number']}',
              onTap: () async {
                try {
                  final phoneUri = Uri.parse('tel:+254${user['phone_number']}');
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  } else {
                    Fluttertoast.showToast(msg: 'Could not make call');
                  }
                } catch (e) {
                  debugPrint('Error launching phone: $e');
                  Fluttertoast.showToast(msg: 'Could not make call');
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: MainColors.primary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MainColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: MainColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: MainColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _bloodIcon(String bloodType) {
    return SvgPicture.asset(
      BloodTypeUtils.fromName(bloodType).icon,
      height: 50,
    );
  }

  Future<void> _sendSMS(BuildContext context, Map<String, dynamic> user, String phone) async {
    // Determine the message based on whether the viewed user is a donor, recipient, or organization
    final viewedUserRole = user['user_role'] as String? ?? 'donor';
    final viewedUserName = user['name'] as String;
    final currentUserName = _currentUser?['name'] as String? ?? 'Someone';
    
    String message;
    
    if (viewedUserRole == 'organization') {
      // Message to organization
      message = 'Hello $viewedUserName, I found your organization on the Blood Donation app. I would like to get in touch regarding blood donation services. Please let me know how I can assist or if you have any availability. Thank you! - $currentUserName';
    } else if (viewedUserRole == 'donor') {
      // Current user (recipient) is requesting blood from a donor
      final viewedUserBloodType = user['blood_type'] as String;
      message = 'Hello $viewedUserName, I found your profile on the Blood Donation app. I am in need of $viewedUserBloodType blood type. If you are available and willing to donate, it would be greatly appreciated. Please let me know your availability. Thank you! - $currentUserName';
    } else {
      // Current user (donor) is offering blood to a recipient
      final currentUserBloodType = _currentUser?['blood_type'] as String? ?? 'blood';
      message = 'Hello $viewedUserName, I found your profile on the Blood Donation app. I am a blood donor with $currentUserBloodType blood type. If you are in need of blood, I would be happy to help. Please let me know if you are still in need. Thank you! - $currentUserName';
    }
    
    try {
      final smsUri = Uri.parse('sms:+254$phone?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: 'Could not send SMS');
      }
    } catch (e) {
      debugPrint('Error launching SMS: $e');
      Fluttertoast.showToast(msg: 'Could not send SMS');
    }
  }

  Future<void> _sendEmail(BuildContext context, Map<String, dynamic> user) async {
    // Get current user's details for the email
    final currentUserName = _currentUser?['name'] as String? ?? 'User';
    final currentUserEmail = _currentUser?['email'] as String? ?? '';
    final currentUserPhone = _currentUser?['phone_number'] as String? ?? '';
    final currentUserBloodType = _currentUser?['blood_type'] as String? ?? '';
    final viewedUserRole = user['user_role'] as String? ?? 'donor';
    
    // Format subject
    final subject = viewedUserRole == 'organization'
        ? 'Inquiry from $currentUserName - Blood Donation App'
        : 'Blood Donation request from $currentUserName';
    
    // Format body based on recipient type
    String body;
    if (viewedUserRole == 'organization') {
      body = 'Inquiry from Blood Donation App\n\n'
          'Name: $currentUserName\n'
          'Phone: ${currentUserPhone.isNotEmpty ? currentUserPhone : "Not provided"}\n'
          'Email: $currentUserEmail\n\n'
          'I would like to get in touch regarding blood donation services.';
    } else {
      body = 'Blood Donation Request\n\n'
          'Name: $currentUserName\n'
          'Phone: ${currentUserPhone.isNotEmpty ? currentUserPhone : "Not provided"}\n'
          'Email: $currentUserEmail\n'
          'Blood Group: $currentUserBloodType';
    }
    
    final email = user['email'] as String;
    
    try {
      if (Platform.isAndroid) {
        // Android: Try to open Gmail app specifically
        
        // Method 1: Try Gmail app directly using intent URL (targets Gmail package specifically)
        try {
          // Most reliable: Use intent with explicit Gmail package
          final encodedSubject = Uri.encodeComponent(subject);
          final encodedBody = Uri.encodeComponent(body);
          final gmailIntentUrl = Uri.parse(
            'intent://send?to=$email&subject=$encodedSubject&body=$encodedBody#Intent;scheme=mailto;package=com.google.android.gm;end'
          );
          
          await launchUrl(gmailIntentUrl, mode: LaunchMode.externalApplication);
          return; // Success - Gmail app opened
        } catch (e) {
          debugPrint('Gmail Intent Method 1 failed: $e');
        }
        
        // Method 2: Alternative intent format for Gmail
        try {
          final gmailIntentUrl2 = Uri.parse(
            'intent://send/#Intent;scheme=mailto;package=com.google.android.gm;S.browser_fallback_url=${Uri.encodeComponent('https://mail.google.com/mail/?view=cm&fs=1&tf=1&to=$email&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}')};S.subject=${Uri.encodeComponent(subject)};S.body=${Uri.encodeComponent(body)};S.to=$email;end'
          );
          
          await launchUrl(gmailIntentUrl2, mode: LaunchMode.externalApplication);
          return;
        } catch (e) {
          debugPrint('Gmail Intent Method 2 failed: $e');
        }
        
        // Method 3: Use mailto but with Gmail package specification
        try {
          // Create intent that targets Gmail specifically
          final gmailMailtoIntent = Uri.parse(
            'intent:///send?to=$email&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}#Intent;scheme=mailto;package=com.google.android.gm;end'
          );
          
          await launchUrl(gmailMailtoIntent, mode: LaunchMode.externalApplication);
          return;
        } catch (e) {
          debugPrint('Gmail mailto intent failed: $e');
        }
        
        // Method 4: Gmail web compose (opens in browser/Gmail app if available)
        try {
          final gmailComposeUrl = Uri.parse(
            'https://mail.google.com/mail/?view=cm&fs=1&tf=1&to=$email&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}'
          );
          
          await launchUrl(gmailComposeUrl, mode: LaunchMode.externalApplication);
          return;
        } catch (e) {
          debugPrint('Gmail compose URL failed: $e');
        }
      } else if (Platform.isIOS) {
        // iOS: Try Gmail app URL scheme first
        try {
          final gmailIosUrl = Uri.parse(
            'googlegmail://co?to=$email&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}'
          );
          
          // Try launching directly (canLaunchUrl can be unreliable)
          await launchUrl(gmailIosUrl);
          return; // Success - Gmail app opened
        } catch (e) {
          debugPrint('Gmail iOS URL failed: $e');
        }
        
        // iOS fallback: Try mailto (but prefer Gmail)
        try {
          final mailtoUri = Uri(
            scheme: 'mailto',
            path: email,
            queryParameters: {
              'subject': subject,
              'body': body,
            },
          );
          
          await launchUrl(mailtoUri);
          return;
        } catch (e) {
          debugPrint('Mailto fallback failed: $e');
        }
      }
      
      // If all methods failed, show error
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Gmail app not found. Please install Gmail from Play Store/App Store.',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      debugPrint('Error launching Gmail: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Could not open Gmail app. Please install Gmail.',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  void _showContactOptions(BuildContext context) {
    final user = widget.user;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact ${user['name']}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            if (user['phone_number'] != null && (user['phone_number'] as String).isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.phone, color: MainColors.primary),
                title: const Text('Call'),
                subtitle: Text('+254${user['phone_number']}'),
                    onTap: () async {
                      try {
                        final phone = user['phone_number'] as String;
                        final phoneUri = Uri.parse('tel:+254$phone');
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                          Navigator.pop(context);
                        } else {
                          Fluttertoast.showToast(msg: 'Could not make call');
                        }
                      } catch (e) {
                        debugPrint('Error launching phone: $e');
                        Fluttertoast.showToast(msg: 'Could not make call');
                      }
                    },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.chat, color: MainColors.primary),
              title: const Text('Send SMS'),
              subtitle: Text(user['phone_number'] != null && (user['phone_number'] as String).isNotEmpty
                  ? '+254${user['phone_number']}'
                  : 'No phone number available'),
              onTap: () async {
                try {
                  final phone = user['phone_number'] as String?;
                  if (phone == null || phone.isEmpty) {
                    Fluttertoast.showToast(msg: 'No phone number available');
                    Navigator.pop(context);
                    return;
                  }
                  await _sendSMS(context, user, phone);
                } catch (e) {
                  debugPrint('Error launching SMS: $e');
                  Fluttertoast.showToast(msg: 'Could not send SMS');
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email, color: MainColors.primary),
              title: const Text('Send Email'),
              subtitle: Text(user['email'] as String),
              onTap: () async {
                await _sendEmail(context, user);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
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

