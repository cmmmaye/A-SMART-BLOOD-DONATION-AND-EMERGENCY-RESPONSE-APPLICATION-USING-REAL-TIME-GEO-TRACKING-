import 'package:flutter/material.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../data/message.dart';
import '../utils/tools.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  static const route = 'chat-list';
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  Map<int, Map<String, dynamic>> _otherUsers = {};
  Map<int, int> _unreadCounts = {};
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _startPolling();
  }

  Future<void> _loadConversations() async {
    final userId = UserSession.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _currentUserId = userId;
      _isLoading = true;
    });

    try {
      final conversations = await DatabaseHelper.instance.getConversations(userId);
      
      // Get unread counts
      final unreadCount = await DatabaseHelper.instance.getUnreadMessageCount(userId);
      
      // Load other user details
      final otherUserIds = <int>{};
      for (var conv in conversations) {
        final otherId = conv['other_user_id'] as int;
        otherUserIds.add(otherId);
      }

      final otherUsers = <int, Map<String, dynamic>>{};
      for (var otherId in otherUserIds) {
        final user = await DatabaseHelper.instance.getUserById(otherId);
        if (user != null) {
          otherUsers[otherId] = user;
        }
      }

      // Get unread counts per conversation
      final unreadCounts = <int, int>{};
      for (var conv in conversations) {
        final otherId = conv['other_user_id'] as int;
        final messages = await DatabaseHelper.instance.getMessages(
          userId: userId,
          otherUserId: otherId,
        );
        final unread = messages
            .where((m) => m['receiver_id'] == userId && m['is_read'] == 0)
            .length;
        unreadCounts[otherId] = unread;
      }

      setState(() {
        _conversations = conversations;
        _otherUsers = otherUsers;
        _unreadCounts = unreadCounts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    // Poll for new messages every 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkForNewMessages();
        _loadConversations();
        _startPolling();
      }
    });
  }

  Future<void> _checkForNewMessages() async {
    if (_currentUserId == null) return;
    
    try {
      final unreadCount = await DatabaseHelper.instance.getUnreadMessageCount(_currentUserId!);
      if (unreadCount > 0 && mounted) {
        // Show a visual indicator or notification
        // For now, we'll just update the UI which already shows unread badges
      }
    } catch (e) {
      debugPrint('Error checking for new messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start chatting with donors/recipients!',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final otherUserId = conversation['other_user_id'] as int;
                    final otherUser = _otherUsers[otherUserId];
                    
                    if (otherUser == null) return const SizedBox.shrink();

                    final lastMessage = Message.fromDatabaseRow(conversation);
                    final unreadCount = _unreadCounts[otherUserId] ?? 0;

                    return _buildConversationTile(otherUser, lastMessage, unreadCount);
                  },
                ),
    );
  }

  Widget _buildConversationTile(
    Map<String, dynamic> otherUser,
    Message lastMessage,
    int unreadCount,
  ) {
    final isMe = lastMessage.senderId == _currentUserId;
    final messagePreview = isMe
        ? 'You: ${lastMessage.message}'
        : lastMessage.message;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: MainColors.primary,
        child: Text(
          (otherUser['name'] as String? ?? 'U')
              .substring(0, 1)
              .toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser['name'] as String? ?? 'User',
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: MainColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        messagePreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Text(
        Tools.formatTime(lastMessage.createdAt),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(otherUser: otherUser),
          ),
        ).then((_) => _loadConversations());
      },
    );
  }
}

