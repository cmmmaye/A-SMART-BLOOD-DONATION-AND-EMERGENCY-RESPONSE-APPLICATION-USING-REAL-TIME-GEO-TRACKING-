import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../data/donation_offer.dart';
import '../data/medical_center.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';

class SingleDonationOfferScreen extends StatefulWidget {
  final DonationOffer offer;
  const SingleDonationOfferScreen({Key? key, required this.offer}) : super(key: key);

  @override
  _SingleDonationOfferScreenState createState() => _SingleDonationOfferScreenState();
}

class _SingleDonationOfferScreenState extends State<SingleDonationOfferScreen> {
  String? _submittedBy;
  Map<String, dynamic>? _organization;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadOrganization();
  }

  Future<void> _loadUserName() async {
    final user = await DatabaseHelper.instance.getUserById(widget.offer.userId);
    if (user != null) {
      setState(() {
        _submittedBy = user['name'] as String?;
      });
    }
  }

  Future<void> _loadOrganization() async {
    if (widget.offer.organizationId != null) {
      final org = await DatabaseHelper.instance.getUserById(widget.offer.organizationId!);
      if (org != null) {
        setState(() {
          _organization = org;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.bodySmall!.copyWith(fontSize: 14);
    final bodyStyle = textTheme.bodyLarge!.copyWith(fontSize: 16);
    const bodyWrap = EdgeInsets.only(top: 4, bottom: 16);

    return Scaffold(
      appBar: AppBar(title: const Text('Donation Offer Details')),
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
                  '${_submittedBy ?? "Unknown"} on ${Tools.formatDate(widget.offer.createdAt)}',
                  style: bodyStyle,
                ),
              ),
              Text('Blood Type', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                  BloodTypeUtils.bloodTypes[widget.offer.bloodType.index],
                  style: bodyStyle,
                ),
              ),
              Text('Destination', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                  _getDestinationText(),
                  style: bodyStyle,
                ),
              ),
              Text('Donation Date', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Text(
                  Tools.formatDate(widget.offer.donationDate),
                  style: bodyStyle,
                ),
              ),
              Text('Status', style: titleStyle),
              Padding(
                padding: bodyWrap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.offer.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(widget.offer.status)),
                  ),
                  child: Text(
                    widget.offer.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(widget.offer.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (widget.offer.note != null && widget.offer.note!.isNotEmpty) ...[
                Text('Note', style: titleStyle),
                Padding(
                  padding: bodyWrap,
                  child: Text(widget.offer.note, style: bodyStyle),
                ),
              ],
              if (widget.offer.organizationResponse != null && widget.offer.organizationResponse!.isNotEmpty) ...[
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
                      widget.offer.organizationResponse!,
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
                        onPressed: () => _getDirections(),
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
                        onPressed: () => _shareOffer(),
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
                    _showContactOptions(context);
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
              if (widget.offer.userId == UserSession.getCurrentUserId() &&
                  !widget.offer.isFulfilled &&
                  (widget.offer.status == 'accepted' || widget.offer.status == 'pending'))
                _MarkFulfilledBtn(offer: widget.offer),
            ],
          ),
        ),
      ),
    );
  }

  String _getDestinationText() {
    if (widget.offer.destinationCenter != null) {
      switch (widget.offer.destinationType) {
        case DestinationType.hospital:
          return '${widget.offer.destinationCenter!.name} - ${widget.offer.destinationCenter!.location}';
        case DestinationType.redCross:
          return '${widget.offer.destinationCenter!.name} - ${widget.offer.destinationCenter!.location}';
        case DestinationType.bloodBank:
          return '${widget.offer.destinationCenter!.name} - ${widget.offer.destinationCenter!.location}';
        default:
          return '${widget.offer.destinationCenter!.name} - ${widget.offer.destinationCenter!.location}';
      }
    }
    return 'Not specified';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _getDirections() async {
    String? location;
    String? placeName;

    // Try to get location from organization first
    if (_organization != null) {
      location = _organization!['location'] as String?;
      placeName = _organization!['name'] as String?;
    }

    // Fallback to destination center if available
    if ((location == null || location.isEmpty) && widget.offer.destinationCenter != null) {
      location = widget.offer.destinationCenter!.location;
      placeName = widget.offer.destinationCenter!.name;
    }

    if (location == null || location.isEmpty) {
      Fluttertoast.showToast(msg: 'Location not available');
      return;
    }

    // Try to extract coordinates if location contains them
    final locationParts = location.split(',');
    double? latitude;
    double? longitude;

    if (locationParts.length == 2) {
      latitude = double.tryParse(locationParts[0].trim());
      longitude = double.tryParse(locationParts[1].trim());
    }

    if (latitude != null && longitude != null) {
      // Use coordinates for navigation
      // Primary: Google Maps directions URL - this opens Google Maps app directly with directions
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
    } else {
      // Use location name for search
      final searchQuery = placeName != null ? '$placeName $location' : location;
      final encodedLocation = Uri.encodeComponent(searchQuery);
      
      // Google Maps search URL - opens app if installed
      final googleMapsSearchUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedLocation'
      );

      try {
        await launchUrl(googleMapsSearchUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Google Maps search failed: $e');
        Fluttertoast.showToast(
          msg: 'Could not open maps. Please install Google Maps.',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  void _shareOffer() {
    final bloodType = BloodTypeUtils.bloodTypes[widget.offer.bloodType.index];
    final destination = _getDestinationText();
    final donationDate = Tools.formatDate(widget.offer.donationDate);
    final donorName = _submittedBy ?? 'A donor';
    final contactNumber = widget.offer.contactNumber;

    String shareText = 'I am offering to donate $bloodType blood.\n\n';
    shareText += 'Donation Date: $donationDate\n';
    shareText += 'Destination: $destination\n';
    if (widget.offer.note != null && widget.offer.note!.isNotEmpty) {
      shareText += 'Note: ${widget.offer.note}\n';
    }
    shareText += '\nContact: +254$contactNumber';

    Share.share(shareText);
  }

  void _showContactOptions(BuildContext context) {
    // Priority: Organization > Destination Center
    if (_organization != null) {
      _showOrganizationContactOptions(context);
    } else if (widget.offer.destinationCenter != null) {
      _showDestinationCenterContactOptions(context);
    } else {
      Fluttertoast.showToast(msg: 'No contact information available');
    }
  }

  void _showOrganizationContactOptions(BuildContext context) {
    if (_organization == null) return;

    final orgName = _organization!['name'] as String? ?? 'Organization';
    final orgPhone = _organization!['phone_number'] as String?;
    final orgEmail = _organization!['email'] as String?;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact $orgName',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            if (orgPhone != null && orgPhone.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.phone, color: MainColors.primary),
                title: const Text('Call'),
                subtitle: Text(orgPhone),
                onTap: () async {
                  Navigator.pop(context);
                  final cleanedPhone = orgPhone.replaceAll(RegExp(r'[\s-]'), '');
                  final formattedPhone = cleanedPhone.startsWith('0')
                      ? '+254${cleanedPhone.substring(1)}'
                      : cleanedPhone.startsWith('+254')
                          ? cleanedPhone
                          : '+254$cleanedPhone';
                  final url = Uri.parse('tel:$formattedPhone');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    Fluttertoast.showToast(msg: 'Could not make phone call');
                  }
                },
              ),
              const Divider(),
            ],
            if (orgEmail != null && orgEmail.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.email, color: MainColors.primary),
                title: const Text('Email'),
                subtitle: Text(orgEmail),
                onTap: () async {
                  Navigator.pop(context);
                  final url = Uri.parse('mailto:$orgEmail');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    Fluttertoast.showToast(msg: 'Could not open email client');
                  }
                },
              ),
              if (orgPhone != null && orgPhone.isNotEmpty) const Divider(),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDestinationCenterContactOptions(BuildContext context) {
    final center = widget.offer.destinationCenter!;
    final phoneNumbers = center.phoneNumbers;

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
              'Contact ${center.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              center.location,
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
            ] else ...[
              Text(
                'No phone number available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MarkFulfilledBtn extends StatefulWidget {
  final DonationOffer offer;

  const _MarkFulfilledBtn({Key? key, required this.offer}) : super(key: key);

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
                  await DatabaseHelper.instance.updateDonationOfferStatus(
                    int.parse(widget.offer.id),
                    'fulfilled',
                  );
                  
                  if (mounted) {
                    Fluttertoast.showToast(
                      msg: 'Donation offer marked as fulfilled',
                      toastLength: Toast.LENGTH_SHORT,
                    );
                    // Pop with result to indicate the offer was fulfilled
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  debugPrint('Error updating donation offer status: $e');
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

