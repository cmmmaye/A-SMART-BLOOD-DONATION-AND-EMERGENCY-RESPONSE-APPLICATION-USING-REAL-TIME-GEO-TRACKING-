import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../widgets/custom_drawer.dart';
import '../utils/tools.dart';

class MessageAuditScreen extends StatefulWidget {
  static const route = 'message-audit';
  const MessageAuditScreen({Key? key}) : super(key: key);

  @override
  _MessageAuditScreenState createState() => _MessageAuditScreenState();
}

class _MessageAuditScreenState extends State<MessageAuditScreen> {
  List<Map<String, dynamic>> _messages = [];
  Map<int, Map<String, dynamic>> _usersCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadMessages();
  }

  Future<void> _checkAdminAccess() async {
    final user = await UserSession.getCurrentUser();
    if (user == null || user['is_admin'] != true) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await DatabaseHelper.instance.getAllMessages();
      
      // Load user info for all unique user IDs
      final userIds = <int>{};
      for (var msg in messages) {
        userIds.add(msg['sender_id'] as int);
        userIds.add(msg['receiver_id'] as int);
      }

      final usersCache = <int, Map<String, dynamic>>{};
      for (var userId in userIds) {
        final user = await DatabaseHelper.instance.getUserById(userId);
        if (user != null) {
          usersCache[userId] = user;
        }
      }

      setState(() {
        _messages = messages;
        _usersCache = usersCache;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getUserName(int userId) {
    final user = _usersCache[userId];
    if (user == null) return 'Unknown User';
    return user['name'] as String? ?? 'Unknown User';
  }

  String _getUserRole(int userId) {
    final user = _usersCache[userId];
    if (user == null) return 'unknown';
    return user['user_role'] as String? ?? 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Message Audit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No messages found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageCard(message);
                  },
                ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final senderId = message['sender_id'] as int;
    final receiverId = message['receiver_id'] as int;
    final senderName = _getUserName(senderId);
    final receiverName = _getUserName(receiverId);
    final senderRole = _getUserRole(senderId);
    final receiverRole = _getUserRole(receiverId);
    final isRead = ((message['is_read'] as int?) ?? 0) == 1;
    final createdAt = DateTime.parse(message['created_at'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: MainColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(senderRole).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              senderRole.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getRoleColor(senderRole),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'To: $receiverName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(receiverRole).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              receiverRole.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getRoleColor(receiverRole),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),
            Text(
              message['message'] as String,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              Tools.formatDate(createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
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

