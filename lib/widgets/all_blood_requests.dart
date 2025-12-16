import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../common/styles.dart';
import '../database/database_helper.dart';
import '../data/blood_request.dart';
import '../widgets/blood_request_tile.dart';

class AllBloodRequests extends StatefulWidget {
  const AllBloodRequests({Key? key}) : super(key: key);

  @override
  _AllBloodRequestsState createState() => _AllBloodRequestsState();
}

class _AllBloodRequestsState extends State<AllBloodRequests> {
  late Future<List<Map<String, dynamic>>> _requests;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _isInitialized = true;
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

  void _loadRequests() {
    setState(() {
      _requests = DatabaseHelper.instance.getBloodRequests(activeOnly: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Could not fetch blood requests',
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
                      'No requests yet!',
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
                  return BloodRequestTile(
                    request: BloodRequest.fromDatabaseRow(snapshot.data![i]),
                  );
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
