import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../widgets/action_button.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  static const route = 'admin-announcement';
  const AdminAnnouncementScreen({Key? key}) : super(key: key);

  @override
  _AdminAnnouncementScreenState createState() => _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _targetAudience = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = await UserSession.getCurrentUser();
    if (user == null || user['is_admin'] != true) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Only admins can send announcements',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await UserSession.getCurrentUser();
        if (user == null || user['is_admin'] != true) {
          Fluttertoast.showToast(msg: 'Only admins can send announcements');
          setState(() => _isLoading = false);
          return;
        }

        final adminId = user['id'] as int;
        await DatabaseHelper.instance.createAnnouncement(
          adminId: adminId,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          targetAudience: _targetAudience,
        );

        Fluttertoast.showToast(
          msg: 'Announcement sent successfully!',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error sending announcement: $e');
        Fluttertoast.showToast(msg: 'Failed to send announcement');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Announcement'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send a notification to users',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This message will be sent to all selected users',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                _titleField(),
                const SizedBox(height: 16),
                _targetAudienceSelector(),
                const SizedBox(height: 16),
                _messageField(),
                const SizedBox(height: 24),
                ActionButton(
                  text: 'Send Announcement',
                  callback: _sendAnnouncement,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                _buildExamples(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleField() => TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Title',
          hintText: 'e.g., Blood Request Verification',
          prefixIcon: Icon(FontAwesomeIcons.heading),
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? 'Please enter a title'
            : null,
      );

  Widget _targetAudienceSelector() => DropdownButtonFormField<String>(
        value: _targetAudience,
        onChanged: (v) => setState(() => _targetAudience = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Target Audience',
          prefixIcon: Icon(FontAwesomeIcons.users),
        ),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All Users')),
          DropdownMenuItem(value: 'donor', child: Text('Donors Only')),
          DropdownMenuItem(value: 'recipient', child: Text('Recipients Only')),
          DropdownMenuItem(value: 'organization', child: Text('Organizations Only')),
        ],
      );

  Widget _messageField() => TextFormField(
        controller: _messageController,
        maxLines: 8,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Message',
          hintText: 'Enter your announcement message...',
          alignLabelWithHint: true,
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? 'Please enter a message'
            : null,
      );

  Widget _buildExamples() {
    return Card(
      color: MainColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: MainColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Example Messages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MainColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExampleItem(
              'Your blood request has been flagged for verification.',
            ),
            _buildExampleItem(
              'The Kenya Red Cross will contact you shortly.',
            ),
            _buildExampleItem(
              'We noticed your donation post — please confirm your availability.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

