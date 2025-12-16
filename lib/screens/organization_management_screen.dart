import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../widgets/custom_drawer.dart';
import '../screens/edit_organization_screen.dart';

class OrganizationManagementScreen extends StatefulWidget {
  static const route = 'organization-management';
  const OrganizationManagementScreen({Key? key}) : super(key: key);

  @override
  _OrganizationManagementScreenState createState() => _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState extends State<OrganizationManagementScreen> {
  List<Map<String, dynamic>> _organizations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadOrganizations();
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

  Future<void> _loadOrganizations() async {
    setState(() => _isLoading = true);
    try {
      final orgs = await DatabaseHelper.instance.getAllUsers(role: 'organization');
      setState(() {
        _organizations = orgs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading organizations: $e');
      setState(() => _isLoading = false);
    }
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
        return 'Unknown';
    }
  }

  IconData _getOrganizationIcon(String? type) {
    switch (type) {
      case 'hospital':
        return Icons.local_hospital;
      case 'red_cross':
        return FontAwesomeIcons.cross;
      case 'blood_bank':
        return Icons.bloodtype;
      default:
        return Icons.business;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Organization Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _organizations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No organizations found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use "Add Organization" from the menu to create one',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _organizations.length,
                  itemBuilder: (context, index) {
                    final org = _organizations[index];
                    return _buildOrganizationCard(org);
                  },
                ),
    );
  }

  Widget _buildOrganizationCard(Map<String, dynamic> org) {
    final orgType = org['organization_type'] as String?;
    final isBlocked = ((org['is_blocked'] as int?) ?? 0) == 1;
    final isApproved = ((org['is_approved'] as int?) ?? 1) == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: MainColors.primary.withOpacity(0.1),
          child: Icon(
            _getOrganizationIcon(orgType),
            color: MainColors.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                org['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isBlocked)
              const Icon(Icons.block, size: 16, color: Colors.red),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getOrganizationTypeName(orgType)}'),
            if (org['location'] != null) Text('Location: ${org['location']}'),
            if (org['email'] != null) Text('Email: ${org['email']}'),
            if (org['phone_number'] != null)
              Text('Phone: ${org['phone_number']}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green.withOpacity(0.2) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isApproved ? Colors.green : Colors.grey[400]!,
                    ),
                  ),
                  child: Text(
                    isApproved ? 'Approved' : 'Not Approved',
                    style: TextStyle(
                      fontSize: 10,
                      color: isApproved ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ),
                if (isBlocked) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'Blocked',
                      style: TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditOrganizationScreen(organization: org),
              ),
            ).then((_) => _loadOrganizations());
          },
        ),
        onTap: () {
          _showOrganizationDetails(org);
        },
      ),
    );
  }

  void _showOrganizationDetails(Map<String, dynamic> org) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              org['name'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Type', _getOrganizationTypeName(org['organization_type'])),
            if (org['location'] != null)
              _buildDetailRow('Location', org['location'] as String),
            if (org['email'] != null)
              _buildDetailRow('Email', org['email'] as String),
            if (org['phone_number'] != null)
              _buildDetailRow('Phone', org['phone_number'] as String),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditOrganizationScreen(organization: org),
                        ),
                      ).then((_) => _loadOrganizations());
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

