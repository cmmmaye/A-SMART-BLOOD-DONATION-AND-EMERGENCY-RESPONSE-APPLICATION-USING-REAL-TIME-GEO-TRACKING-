import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../widgets/action_button.dart';

class AdminMessageScreen extends StatefulWidget {
  static const route = 'admin-message';
  final Map<String, dynamic>? selectedUser;
  
  const AdminMessageScreen({Key? key, this.selectedUser}) : super(key: key);

  @override
  _AdminMessageScreenState createState() => _AdminMessageScreenState();
}

class _AdminMessageScreenState extends State<AdminMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  Map<String, dynamic>? _selectedUser;
  List<Map<String, dynamic>> _users = [];
  String? _selectedRole;
  bool _isLoading = false;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _selectedUser = widget.selectedUser;
    _loadUsers();
  }

  Future<void> _checkAdminAccess() async {
    final user = await UserSession.getCurrentUser();
    if (user == null || user['is_admin'] != true) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Only admins can send messages',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await DatabaseHelper.instance.getUsersForMessaging(
        role: _selectedRole,
      );
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUser == null) {
        Fluttertoast.showToast(msg: 'Please select a user');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final user = await UserSession.getCurrentUser();
        if (user == null || user['is_admin'] != true) {
          Fluttertoast.showToast(msg: 'Only admins can send messages');
          setState(() => _isLoading = false);
          return;
        }

        final adminId = user['id'] as int;
        final receiverId = _selectedUser!['id'] as int;

        await DatabaseHelper.instance.createMessage(
          senderId: adminId,
          receiverId: receiverId,
          message: _messageController.text.trim(),
        );

        Fluttertoast.showToast(msg: 'Message sent successfully!');
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error sending message: $e');
        Fluttertoast.showToast(msg: 'Failed to send message');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message'),
        actions: [
          DropdownButton<String>(
            value: _selectedRole,
            hint: const Text('Filter'),
            underline: Container(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Users')),
              const DropdownMenuItem(value: 'donor', child: Text('Donors')),
              const DropdownMenuItem(value: 'recipient', child: Text('Recipients')),
              const DropdownMenuItem(value: 'organization', child: Text('Organizations')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value;
                _selectedUser = null;
              });
              _loadUsers();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // User selection section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MainColors.primary.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: MainColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingUsers
                        ? const Center(child: CircularProgressIndicator())
                        : _users.isEmpty
                            ? Text(
                                'No users found',
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            : Container(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _users.length,
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    final isSelected =
                                        _selectedUser?['id'] == user['id'];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => _selectedUser = user);
                                      },
                                      child: Container(
                                        width: 100,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? MainColors.primary
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? MainColors.primary
                                                : Colors.grey[300]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isSelected
                                                  ? Colors.white
                                                  : MainColors.primary
                                                      .withOpacity(0.1),
                                              child: Icon(
                                                _getRoleIcon(
                                                    user['user_role'] as String?),
                                                color: isSelected
                                                    ? MainColors.primary
                                                    : MainColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              child: Text(
                                                user['name'] as String? ?? '',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ],
                ),
              ),
              // Message input section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedUser != null) ...[
                        Text(
                          'To: ${_selectedUser!['name']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedUser!['email'] as String? ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _messageController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Message',
                          hintText: 'Enter your message...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter a message'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      ActionButton(
                        text: 'Send Message',
                        callback: _sendMessage,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'donor':
        return FontAwesomeIcons.droplet;
      case 'recipient':
        return Icons.local_hospital;
      case 'organization':
        return Icons.business;
      default:
        return Icons.person;
    }
  }
}

