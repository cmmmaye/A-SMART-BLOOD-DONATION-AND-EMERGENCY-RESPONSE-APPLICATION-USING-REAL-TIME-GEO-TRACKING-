import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../data/blood_request.dart';
import '../data/donation_offer.dart';
import '../data/medical_center.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';
import '../screens/chat_screen.dart';
import '../screens/organization_profile_screen.dart';
import '../widgets/custom_drawer.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  static const route = 'organization-dashboard';
  const OrganizationDashboardScreen({Key? key}) : super(key: key);

  @override
  _OrganizationDashboardScreenState createState() => _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState extends State<OrganizationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bloodRequests = [];
  List<Map<String, dynamic>> _donationOffers = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  int? _organizationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _startPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = UserSession.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _organizationId = userId;
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getBloodRequestsForOrganization(userId),
        DatabaseHelper.instance.getDonationOffersForOrganization(userId),
        DatabaseHelper.instance.getOrganizationStats(userId),
      ]);

      setState(() {
        _bloodRequests = results[0] as List<Map<String, dynamic>>;
        _donationOffers = results[1] as List<Map<String, dynamic>>;
        _stats = results[2] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading organization data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadData();
        _startPolling();
      }
    });
  }

  Future<void> _handleRequestAction(int requestId, String action) async {
    try {
      await DatabaseHelper.instance.updateBloodRequestStatus(
        requestId,
        action,
        organizationId: _organizationId,
        organizationResponse: action == 'accepted' ? 'Request accepted' : 'Request rejected',
      );
      Fluttertoast.showToast(
        msg: action == 'accepted' ? 'Request accepted' : 'Request rejected',
      );
      _loadData();
    } catch (e) {
      debugPrint('Error updating request: $e');
      Fluttertoast.showToast(msg: 'Failed to update request');
    }
  }

  Future<void> _handleOfferAction(int offerId, String action) async {
    try {
      await DatabaseHelper.instance.updateDonationOfferStatus(
        offerId,
        action,
        organizationId: _organizationId,
        organizationResponse: action == 'accepted' ? 'Offer accepted' : 'Offer rejected',
      );
      Fluttertoast.showToast(
        msg: action == 'accepted' ? 'Offer accepted' : 'Offer rejected',
      );
      _loadData();
    } catch (e) {
      debugPrint('Error updating offer: $e');
      Fluttertoast.showToast(msg: 'Failed to update offer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Organization Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrganizationProfileScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Blood Requests', icon: Icon(Icons.bloodtype)),
            Tab(text: 'Donation Offers', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsCard(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestsList(),
                      _buildOffersList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MainColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MainColors.primary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Requests', _stats['total_requests'] ?? 0),
          _buildStatItem('Accepted', _stats['accepted_requests'] ?? 0),
          _buildStatItem('Pending', _stats['pending_requests'] ?? 0),
          _buildStatItem('Offers', _stats['total_offers'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: MainColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    if (_bloodRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bloodtype, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No blood requests yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bloodRequests.length,
      itemBuilder: (context, index) {
        final request = _bloodRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final isPending = status == 'pending';
    
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
                      Text(
                        request['patient_name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Blood Type: ${request['blood_type']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: MainColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'accepted'
                        ? Colors.green
                        : status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, request['contact_number'] as String),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Request Date: ${Tools.formatDate(DateTime.parse(request['request_date'] as String))}',
            ),
            if (request['note'] != null && (request['note'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.note, request['note'] as String),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleRequestAction(
                        request['id'] as int,
                        'rejected',
                      ),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRequestAction(
                        request['id'] as int,
                        'accepted',
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MainColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!isPending && request['organization_response'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Response: ${request['organization_response']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOffersList() {
    if (_donationOffers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No donation offers yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _donationOffers.length,
      itemBuilder: (context, index) {
        final offer = _donationOffers[index];
        return _buildOfferCard(offer);
      },
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final status = offer['status'] as String;
    final isPending = status == 'pending';
    
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
                      Text(
                        offer['donor_name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Blood Type: ${offer['blood_type']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: MainColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'accepted'
                        ? Colors.green
                        : status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, offer['contact_number'] as String),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Donation Date: ${Tools.formatDate(DateTime.parse(offer['donation_date'] as String))}',
            ),
            if (offer['note'] != null && (offer['note'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.note, offer['note'] as String),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleOfferAction(
                        offer['id'] as int,
                        'rejected',
                      ),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleOfferAction(
                        offer['id'] as int,
                        'accepted',
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MainColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Get donor user info to start chat
                        final donorId = offer['user_id'] as int;
                        final donor = await DatabaseHelper.instance.getUserById(donorId);
                        if (donor != null && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(otherUser: donor),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
                    ),
                  ),
                ],
              ),
            ],
            if (!isPending && offer['organization_response'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Response: ${offer['organization_response']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

