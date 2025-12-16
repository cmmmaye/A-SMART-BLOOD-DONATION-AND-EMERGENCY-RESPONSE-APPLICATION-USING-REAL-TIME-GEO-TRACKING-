import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../widgets/custom_drawer.dart';
import 'user_management_screen.dart';
import 'organization_management_screen.dart';
import 'message_audit_screen.dart';
import 'admin_announcement_screen.dart';
import 'admin_message_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const route = 'admin-dashboard';
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _loadStats();
        _startPolling();
      }
    });
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseHelper.instance.getSystemStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildManagementSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('Total Users', _stats['total_users'] ?? 0, Icons.people, Colors.blue),
        _buildStatCard('Donors', _stats['total_donors'] ?? 0, FontAwesomeIcons.droplet, Colors.red),
        _buildStatCard('Recipients', _stats['total_recipients'] ?? 0, Icons.local_hospital, Colors.orange),
        _buildStatCard('Organizations', _stats['total_organizations'] ?? 0, Icons.business, Colors.green),
        _buildStatCard('Blood Requests', _stats['total_requests'] ?? 0, Icons.bloodtype, Colors.purple),
        _buildStatCard('Pending Requests', _stats['pending_requests'] ?? 0, Icons.pending, Colors.amber),
        _buildStatCard('Donation Offers', _stats['total_offers'] ?? 0, FontAwesomeIcons.heart, Colors.pink),
        _buildStatCard('Pending Offers', _stats['pending_offers'] ?? 0, Icons.pending_actions, Colors.deepOrange),
        _buildStatCard('Total Messages', _stats['total_messages'] ?? 0, Icons.message, Colors.teal),
        _buildStatCard('Unread Messages', _stats['unread_messages'] ?? 0, Icons.mark_email_unread, Colors.indigo),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
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
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildManagementCard(
          title: 'Manage Users',
          subtitle: 'Approve, block, or verify donors and recipients',
          icon: Icons.people,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UserManagementScreen(),
              ),
            ).then((_) => _loadStats());
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          title: 'Manage Organizations',
          subtitle: 'Add or edit hospital, Red Cross, and Blood Bank info',
          icon: Icons.business,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrganizationManagementScreen(),
              ),
            ).then((_) => _loadStats());
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          title: 'Message Audit',
          subtitle: 'View all communications for safety and moderation',
          icon: Icons.message,
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessageAuditScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          title: 'Send Announcement',
          subtitle: 'Broadcast notifications to all users or specific groups',
          icon: Icons.campaign,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminAnnouncementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          title: 'Send Private Message',
          subtitle: 'Send messages to donors, recipients, or organizations',
          icon: Icons.send,
          color: Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminMessageScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

