import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../widgets/custom_drawer.dart';
import '../screens/view_user_profile_screen.dart';

class UserManagementScreen extends StatefulWidget {
  static const route = 'user-management';
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  String? _selectedRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadUsers();
  }

  Future<void> _checkAdminAccess() async {
    final user = await UserSession.getCurrentUser();
    if (user == null || user['is_admin'] != true) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Only admins can access this screen',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await DatabaseHelper.instance.getAllUsers(role: _selectedRole);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserStatus(int userId, String action, bool value) async {
    try {
      bool? isApproved;
      bool? isBlocked;
      bool? isVerified;
      
      switch (action) {
        case 'approve':
          isApproved = value;
          break;
        case 'block':
          isBlocked = value;
          break;
        case 'verify':
          isVerified = value;
          break;
      }

      await DatabaseHelper.instance.updateUser(
        id: userId,
        isApproved: isApproved,
        isBlocked: isBlocked,
        isVerified: isVerified,
      );
      Fluttertoast.showToast(
        msg: value
            ? 'User ${action}d successfully'
            : 'User ${action} removed successfully',
      );
      _loadUsers();
    } catch (e) {
      debugPrint('Error updating user: $e');
      Fluttertoast.showToast(msg: 'Failed to update user');
    }
  }

  Future<void> _deleteUser(int userId, String userName) async {
    // Check if trying to delete an admin
    final userToDelete = await DatabaseHelper.instance.getUserById(userId);
    if (userToDelete != null && (userToDelete['is_admin'] as bool?) == true) {
      Fluttertoast.showToast(
        msg: 'Cannot delete admin accounts',
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    // Check if trying to delete current user
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser != null && currentUser['id'] == userId) {
      Fluttertoast.showToast(
        msg: 'Cannot delete your own account',
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "$userName"?\n\nThis action cannot be undone and will delete all associated data (requests, offers, messages).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteUser(userId);
        Fluttertoast.showToast(
          msg: 'User deleted successfully',
          toastLength: Toast.LENGTH_LONG,
        );
        _loadUsers();
      } catch (e) {
        debugPrint('Error deleting user: $e');
        Fluttertoast.showToast(msg: 'Failed to delete user');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('User Management'),
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
              setState(() => _selectedRole = value);
              _loadUsers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserCard(user);
                  },
                ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isApproved = ((user['is_approved'] as int?) ?? 1) == 1;
    final isBlocked = ((user['is_blocked'] as int?) ?? 0) == 1;
    final isVerified = ((user['is_verified'] as int?) ?? 0) == 1;
    final userRole = user['user_role'] as String? ?? 'donor';
    final isAdmin = ((user['is_admin'] as int?) ?? 0) == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.orange : _getRoleColor(userRole),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : _getRoleIcon(userRole),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isAdmin)
              const Icon(Icons.admin_panel_settings, size: 16, color: Colors.orange),
            if (isVerified)
              const Icon(Icons.verified, size: 16, color: Colors.blue),
            if (isBlocked)
              const Icon(Icons.block, size: 16, color: Colors.red),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user['email']}'),
            Text('Role: ${isAdmin ? 'ADMIN' : userRole.toUpperCase()}'),
            if (user['phone_number'] != null)
              Text('Phone: ${user['phone_number']}'),
            Row(
              children: [
                _buildStatusChip('Approved', isApproved, Colors.green),
                const SizedBox(width: 4),
                _buildStatusChip('Blocked', isBlocked, Colors.red),
                const SizedBox(width: 4),
                _buildStatusChip('Verified', isVerified, Colors.blue),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              child: Row(
                children: [
                  Icon(isApproved ? Icons.cancel : Icons.check_circle, size: 20),
                  const SizedBox(width: 8),
                  Text(isApproved ? 'Unapprove' : 'Approve'),
                ],
              ),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _updateUserStatus(
                    user['id'] as int,
                    'approve',
                    !isApproved,
                  );
                });
              },
            ),
            PopupMenuItem<String>(
              child: Row(
                children: [
                  Icon(isBlocked ? Icons.lock_open : Icons.block, size: 20),
                  const SizedBox(width: 8),
                  Text(isBlocked ? 'Unblock' : 'Block'),
                ],
              ),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _updateUserStatus(
                    user['id'] as int,
                    'block',
                    !isBlocked,
                  );
                });
              },
            ),
            PopupMenuItem<String>(
              child: Row(
                children: [
                  Icon(isVerified ? Icons.verified_user_outlined : Icons.verified_user, size: 20),
                  const SizedBox(width: 8),
                  Text(isVerified ? 'Unverify' : 'Verify'),
                ],
              ),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _updateUserStatus(
                    user['id'] as int,
                    'verify',
                    !isVerified,
                  );
                });
              },
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              child: const Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('View Profile'),
                ],
              ),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewUserProfileScreen(user: user),
                    ),
                  );
                });
              },
            ),
            // Only show delete option for non-admin users
            if (!isAdmin)
              PopupMenuItem<String>(
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete User', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _deleteUser(
                      user['id'] as int,
                      user['name'] as String,
                    );
                  });
                },
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewUserProfileScreen(user: user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isActive ? color : Colors.grey[600],
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'donor':
        return FontAwesomeIcons.droplet;
      case 'recipient':
        return Icons.local_hospital;
      case 'organization':
        return Icons.business;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'donor':
        return Colors.red;
      case 'recipient':
        return Colors.orange;
      case 'organization':
        return Colors.green;
      case 'admin':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

