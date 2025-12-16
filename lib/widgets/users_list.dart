import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/styles.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../screens/view_user_profile_screen.dart';
import '../screens/chat_screen.dart';

class UsersList extends StatefulWidget {
  const UsersList({Key? key}) : super(key: key);

  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late Future<List<Map<String, dynamic>>> _users;

  @override
  void initState() {
    super.initState();
    _users = _initializeUsers();
  }

  Future<List<Map<String, dynamic>>> _initializeUsers() async {
    try {
      // Get current user's role
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        return [];
      }

      final currentUserRole = currentUser['user_role'] as String? ?? 'donor';
      
      // Donors see Recipients, Recipients see Donors
      final targetRole = currentUserRole == 'donor' ? 'recipient' : 'donor';
      
      return await DatabaseHelper.instance.getUsersByRole(targetRole);
    } catch (e) {
      debugPrint('Error loading users: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _users,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('UsersList error: ${snapshot.error}');
          debugPrint('Stack trace: ${snapshot.stackTrace}');
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Could not fetch users',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data?.isEmpty ?? true) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(IconAssets.bloodBag, height: 140),
                    const SizedBox(height: 16),
                    const Text(
                      'No users found',
                      style: TextStyle(fontFamily: Fonts.logo, fontSize: 20),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  return _UserTile(user: snapshot.data![i]);
                },
                childCount: snapshot.data!.length,
              ),
            );
          }
        }

        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _UserTile extends StatefulWidget {
  final Map<String, dynamic> user;

  const _UserTile({Key? key, required this.user}) : super(key: key);

  @override
  _UserTileState createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
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

  Future<void> _sendSMS(BuildContext context, String phone) async {
    // Determine the message based on whether the viewed user is a donor or recipient
    final viewedUserRole = widget.user['user_role'] as String? ?? 'donor';
    final viewedUserName = widget.user['name'] as String;
    final viewedUserBloodType = widget.user['blood_type'] as String;
    
    String message;
    
    if (viewedUserRole == 'donor') {
      // Current user (recipient) is requesting blood from a donor
      final currentUserName = _currentUser?['name'] as String? ?? 'Someone';
      message = 'Hello $viewedUserName, I found your profile on the Blood Donation app. I am in need of $viewedUserBloodType blood type. If you are available and willing to donate, it would be greatly appreciated. Please let me know your availability. Thank you! - $currentUserName';
    } else {
      // Current user (donor) is offering blood to a recipient
      final currentUserName = _currentUser?['name'] as String? ?? 'Someone';
      final currentUserBloodType = _currentUser?['blood_type'] as String? ?? 'blood';
      message = 'Hello $viewedUserName, I found your profile on the Blood Donation app. I am a blood donor with $currentUserBloodType blood type. If you are in need of blood, I would be happy to help. Please let me know if you are still in need. Thank you! - $currentUserName';
    }
    
    final url = 'sms:+254$phone?body=${Uri.encodeComponent(message)}';
    
    if (await canLaunch(url)) {
      await launch(url);
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: 'Could not send SMS');
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    // Determine the message based on whether the viewed user is a donor or recipient
    final viewedUserRole = widget.user['user_role'] as String? ?? 'donor';
    final viewedUserName = widget.user['name'] as String;
    final viewedUserBloodType = widget.user['blood_type'] as String;
    
    String subject;
    String body;
    
    if (viewedUserRole == 'donor') {
      // Current user (recipient) is requesting blood from a donor
      final currentUserName = _currentUser?['name'] as String? ?? 'Someone';
      subject = 'Blood Donation Request';
      body = 'Hello $viewedUserName,\n\n'
          'I hope this message finds you well. I found your profile on the Blood Donation app and I am reaching out to request your assistance.\n\n'
          'I am in need of $viewedUserBloodType blood type. If you are available and willing to donate, it would be greatly appreciated.\n\n'
          'Please let me know your availability and we can coordinate a suitable time and location.\n\n'
          'Thank you for your consideration and for being a donor!\n\n'
          'Best regards,\n$currentUserName';
    } else {
      // Current user (donor) is offering blood to a recipient
      final currentUserName = _currentUser?['name'] as String? ?? 'Someone';
      final currentUserBloodType = _currentUser?['blood_type'] as String? ?? 'blood';
      subject = 'Blood Donation Offer';
      body = 'Hello $viewedUserName,\n\n'
          'I hope this message finds you well. I found your profile on the Blood Donation app and I am reaching out to offer my assistance.\n\n'
          'I am a blood donor with $currentUserBloodType blood type. If you are in need of blood, I would be happy to help.\n\n'
          'Please let me know if you are still in need and we can coordinate a suitable time and location.\n\n'
          'Thank you for considering my offer.\n\n'
          'Best regards,\n$currentUserName';
    }
    
    final email = widget.user['email'] as String;
    final url = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    
    if (await canLaunch(url)) {
      await launch(url);
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: 'Could not open email');
    }
  }

  void _showContactOptions(BuildContext context) {
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
              'Contact ${widget.user['name']}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            if (widget.user['phone_number'] != null && (widget.user['phone_number'] as String).isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.phone, color: MainColors.primary),
                title: const Text('Call'),
                subtitle: Text('+254${widget.user['phone_number']}'),
                onTap: () async {
                  final phone = widget.user['phone_number'] as String;
                  final url = 'tel:+254$phone';
                  if (await canLaunch(url)) {
                    await launch(url);
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(msg: 'Could not make call');
                  }
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.chat, color: MainColors.primary),
              title: const Text('Send SMS'),
              subtitle: Text(widget.user['phone_number'] != null && (widget.user['phone_number'] as String).isNotEmpty
                  ? '+254${widget.user['phone_number']}'
                  : 'No phone number available'),
              onTap: () async {
                final phone = widget.user['phone_number'] as String?;
                if (phone == null || phone.isEmpty) {
                  Fluttertoast.showToast(msg: 'No phone number available');
                  Navigator.pop(context);
                  return;
                }
                await _sendSMS(context, phone);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email, color: MainColors.primary),
              title: const Text('Send Email'),
              subtitle: Text(widget.user['email'] as String),
              onTap: () {
                _sendEmail(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user['name'] as String,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user['email'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MainColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.user['blood_type'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewUserProfileScreen(user: widget.user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(otherUser: widget.user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

