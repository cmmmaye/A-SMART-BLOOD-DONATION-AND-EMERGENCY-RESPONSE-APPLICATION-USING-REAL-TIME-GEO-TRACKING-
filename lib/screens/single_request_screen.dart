import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../data/blood_request.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';

class SingleRequestScreen extends StatefulWidget {
  final BloodRequest request;
  const SingleRequestScreen({Key? key, required this.request}) : super(key: key);

  @override
  _SingleRequestScreenState createState() => _SingleRequestScreenState();
}

class _SingleRequestScreenState extends State<SingleRequestScreen> {
  String? _submittedBy;
  BloodRequest? _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _loadUserName();
    _refreshRequest();
    _startPolling();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startPolling() {
    // Poll every 5 seconds to check for status updates from organizations
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _refreshRequest();
        _startPolling();
      }
    });
  }

  Future<void> _refreshRequest() async {
    try {
      final requests = await DatabaseHelper.instance.getBloodRequests(
        userId: widget.request.userId,
        activeOnly: false,
      );
      final updatedRequest = requests.firstWhere(
        (r) => r['id'].toString() == widget.request.id,
        orElse: () => {},
      );
      if (updatedRequest.isNotEmpty) {
        setState(() {
          _currentRequest = BloodRequest.fromDatabaseRow(updatedRequest);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing request: $e');
    }
  }

  Future<void> _loadUserName() async {
    final user = await DatabaseHelper.instance.getUserById(widget.request.userId);
    if (user != null) {
      setState(() {
        _submittedBy = user['name'] as String?;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'fulfilled':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _currentRequest ?? widget.request;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.bodySmall!.copyWith(fontSize: 14);
    final bodyStyle = textTheme.bodyLarge!.copyWith(fontSize: 16);
    const bodyWrap = EdgeInsets.only(top: 4, bottom: 16);

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Request Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submitted By', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                  '${_submittedBy ?? "Unknown"} on ${Tools.formatDate(request.createdAt)}',
                  style: bodyStyle,
                ),
              ),
              Text('Patient Name', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(request.patientName, style: bodyStyle),
              ),
              Text('Location', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                  '${request.medicalCenter.name} - ${request.medicalCenter.location}',
                  style: bodyStyle,
                ),
              ),
              Text('Blood Type', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(request.bloodType.name, style: bodyStyle),
              ),
              Text('Possible Donors', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                    request.bloodType.possibleDonors
                        .map((e) => e.name)
                        .join('   /   '),
                    style: bodyStyle),
              ),
              Text('Status', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(request.status)),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!Tools.isNullOrEmpty(request.note)) ...[
                Text('Notes', style: titleStyle),
                Padding(
                  padding: bodyWrap,
                  child: Text(request.note, style: bodyStyle),
                ),
              ],
              if (request.organizationResponse != null && request.organizationResponse!.isNotEmpty) ...[
                Text('Organization Response', style: titleStyle),
                Padding(
                  padding: bodyWrap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.organizationResponse!,
                      style: bodyStyle.copyWith(color: Colors.blue),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all(
                            MainColors.primaryDark,
                          ),
                        ),
                        onPressed: () async {
                          final latitude = request.medicalCenter.latitude;
                          final longitude = request.medicalCenter.longitude;
                          final placeName = request.medicalCenter.name;
                          
                          // Primary: Google Maps directions URL - opens Google Maps app directly with directions
                          final googleMapsDirectionsUrl = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving'
                          );
                          
                          // Android-specific: Direct navigation intent (opens Google Maps navigation mode)
                          final androidNavigationUrl = Uri.parse(
                            'google.navigation:q=$latitude,$longitude'
                          );
                          
                          // iOS-specific: Apple Maps navigation
                          final appleMapsUrl = Uri.parse(
                            'http://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d'
                          );
                          
                          bool launched = false;
                          
                          // Try Android navigation intent first (directly opens Google Maps navigation)
                          try {
                            await launchUrl(androidNavigationUrl, mode: LaunchMode.externalApplication);
                            launched = true;
                            debugPrint('Successfully launched Android navigation');
                          } catch (e) {
                            debugPrint('Android navigation failed: $e');
                            
                            // Try Google Maps directions URL (opens app if installed, browser if not)
                            try {
                              await launchUrl(googleMapsDirectionsUrl, mode: LaunchMode.externalApplication);
                              launched = true;
                              debugPrint('Successfully launched Google Maps directions');
                            } catch (e2) {
                              debugPrint('Google Maps directions failed: $e2');
                              
                              // Try Apple Maps as fallback (for iOS)
                              try {
                                await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
                                launched = true;
                                debugPrint('Successfully launched Apple Maps');
                              } catch (e3) {
                                debugPrint('Apple Maps failed: $e3');
                              }
                            }
                          }
                          
                          if (!launched) {
                            Fluttertoast.showToast(
                              msg: 'Could not open maps. Please install Google Maps.',
                              toastLength: Toast.LENGTH_LONG,
                            );
                          }
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Get Directions'),
                      ),
                    ),
                    const VerticalDivider(thickness: 1),
                    Expanded(
                      child: TextButton.icon(
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all(
                            MainColors.primaryDark,
                          ),
                        ),
                        onPressed: () {
                          Share.share(
                            '${request.patientName} needs ${request.bloodType.name} '
                            'blood by ${Tools.formatDate(request.requestDate)}.\n'
                            'You can donate by visiting ${request.medicalCenter.name} located in '
                            '${request.medicalCenter.location}.\n\n'
                            'Contact +254${request.contactNumber} for more info.',
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 24,
                ),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      MainColors.primary,
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.all(12),
                    ),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    )),
                  ),
                  onPressed: () {
                    _showMedicalCenterContactOptions(context);
                  },
                  child: Center(
                    child: Text(
                      'Contact',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium!.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              if (request.userId == UserSession.getCurrentUserId() &&
                  !request.isFulfilled &&
                  (request.status == 'accepted' || request.status == 'pending'))
                _MarkFulfilledBtn(request: request),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalCenterContactOptions(BuildContext context) {
    final request = _currentRequest ?? widget.request;
    final medicalCenter = request.medicalCenter;
    final phoneNumbers = medicalCenter.phoneNumbers;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact ${medicalCenter.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              medicalCenter.location,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (phoneNumbers.isNotEmpty) ...[
              ...phoneNumbers.asMap().entries.map((entry) {
                final index = entry.key;
                final phoneNumber = entry.value;
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone, color: MainColors.primary),
                      title: Text('Call ${phoneNumbers.length > 1 ? "(${index + 1})" : ""}'),
                      subtitle: Text(phoneNumber.startsWith('0') 
                          ? '+254${phoneNumber.substring(1)}' 
                          : phoneNumber.startsWith('+254')
                              ? phoneNumber
                              : '+254$phoneNumber'),
                      onTap: () async {
                        final formattedPhone = phoneNumber.startsWith('0')
                            ? '+254${phoneNumber.substring(1)}'
                            : phoneNumber.startsWith('+254')
                                ? phoneNumber
                                : '+254$phoneNumber';
                        final url = Uri.parse('tel:$formattedPhone');
                        try {
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                            Navigator.pop(context);
                          } else {
                            Fluttertoast.showToast(msg: 'Could not make call');
                          }
                        } catch (e) {
                          debugPrint('Error launching phone: $e');
                          Fluttertoast.showToast(msg: 'Could not make call');
                        }
                      },
                    ),
                    if (index < phoneNumbers.length - 1) const Divider(),
                  ],
                );
              }),
              const Divider(),
            ],
            if (phoneNumbers.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.chat, color: MainColors.primary),
                title: const Text('Send SMS'),
                subtitle: Text(phoneNumbers.isNotEmpty
                    ? (phoneNumbers.first.startsWith('0')
                        ? '+254${phoneNumbers.first.substring(1)}'
                        : phoneNumbers.first.startsWith('+254')
                            ? phoneNumbers.first
                            : '+254${phoneNumbers.first}')
                    : 'No phone number available'),
                onTap: () async {
                  if (phoneNumbers.isEmpty) {
                    Fluttertoast.showToast(msg: 'No phone number available');
                    Navigator.pop(context);
                    return;
                  }
                  final phoneNumber = phoneNumbers.first;
                  final formattedPhone = phoneNumber.startsWith('0')
                      ? '+254${phoneNumber.substring(1)}'
                      : phoneNumber.startsWith('+254')
                          ? phoneNumber
                          : '+254$phoneNumber';
                  final url = Uri.parse('sms:$formattedPhone');
                  try {
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                      Navigator.pop(context);
                    } else {
                      Fluttertoast.showToast(msg: 'Could not send SMS');
                    }
                  } catch (e) {
                    debugPrint('Error launching SMS: $e');
                    Fluttertoast.showToast(msg: 'Could not send SMS');
                  }
                },
              ),
            // Also show option to contact the requester
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: MainColors.primary),
              title: const Text('Contact Requester'),
              subtitle: Text('+254${request.contactNumber}'),
              onTap: () async {
                final contact = Uri.parse('tel:+254${request.contactNumber}');
                try {
                  if (await canLaunchUrl(contact)) {
                    await launchUrl(contact);
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(msg: 'Could not make call');
                  }
                } catch (e) {
                  debugPrint('Error launching phone: $e');
                  Fluttertoast.showToast(msg: 'Could not make call');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkFulfilledBtn extends StatefulWidget {
  final BloodRequest request;

  const _MarkFulfilledBtn({Key? key, required this.request}) : super(key: key);

  @override
  _MarkFulfilledBtnState createState() => _MarkFulfilledBtnState();
}

class _MarkFulfilledBtnState extends State<_MarkFulfilledBtn> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  Colors.green[600],
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.all(12),
                ),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                )),
              ),
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await DatabaseHelper.instance.updateBloodRequestStatus(
                    int.parse(widget.request.id),
                    'fulfilled',
                  );
                  
                  if (mounted) {
                    Fluttertoast.showToast(
                      msg: 'Request marked as fulfilled',
                      toastLength: Toast.LENGTH_SHORT,
                    );
                    // Pop with result to indicate the request was fulfilled
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  debugPrint('Error updating request status: $e');
                  if (mounted) {
                    Fluttertoast.showToast(
                      msg: 'Something went wrong. Please try again',
                    );
                  }
                  setState(() => _isLoading = false);
                }
              },
              child: Center(
                child: Text(
                  'Mark as Fulfilled',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
          );
  }
}
