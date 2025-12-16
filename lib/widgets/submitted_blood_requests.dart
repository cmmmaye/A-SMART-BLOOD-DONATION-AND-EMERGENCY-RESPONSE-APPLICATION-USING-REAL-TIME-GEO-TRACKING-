import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/styles.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../data/blood_request.dart';
import 'blood_request_tile.dart';

class SubmittedBloodRequests extends StatefulWidget {
  final bool activeOnly;

  const SubmittedBloodRequests({
    Key? key,
    this.activeOnly = true,
  }) : super(key: key);

  @override
  _SubmittedBloodRequestsState createState() => _SubmittedBloodRequestsState();
}

class _SubmittedBloodRequestsState extends State<SubmittedBloodRequests> {
  late Future<List<Map<String, dynamic>>> _submittedRequests;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _isInitialized = true;
    _startPolling();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen (but not on first build)
    if (_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRequests();
        }
      });
    }
  }

  void _startPolling() {
    // Poll every 5 seconds to check for status updates from organizations
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadRequests();
        _startPolling();
      }
    });
  }

  void _loadRequests() {
    setState(() {
      final userId = UserSession.getCurrentUserId();
      if (userId == null) {
        _submittedRequests = Future.value(<Map<String, dynamic>>[]);
        return;
      }
      
      _submittedRequests = DatabaseHelper.instance.getBloodRequests(
        userId: userId,
        activeOnly: widget.activeOnly,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _submittedRequests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not fetch submitted requests',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data?.isEmpty ?? true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(IconAssets.bloodBag, height: 140),
                  const SizedBox(height: 16),
                  const Text(
                    'No requests yet!',
                    style: TextStyle(fontFamily: Fonts.logo, fontSize: 20),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, i) {
                return BloodRequestTile(
                  request: BloodRequest.fromDatabaseRow(snapshot.data![i]),
                );
              },
            );
          }
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
