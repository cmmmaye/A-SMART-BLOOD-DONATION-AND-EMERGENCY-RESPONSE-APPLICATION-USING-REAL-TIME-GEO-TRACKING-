import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/styles.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../data/donation_offer.dart';
import '../screens/single_donation_offer_screen.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';

class SubmittedDonationOffers extends StatefulWidget {
  final bool activeOnly;

  const SubmittedDonationOffers({
    Key? key,
    this.activeOnly = true,
  }) : super(key: key);

  @override
  _SubmittedDonationOffersState createState() => _SubmittedDonationOffersState();
}

class _SubmittedDonationOffersState extends State<SubmittedDonationOffers> {
  late Future<List<Map<String, dynamic>>> _submittedOffers;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadOffers();
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
          _loadOffers();
        }
      });
    }
  }

  void _startPolling() {
    // Poll every 5 seconds to check for status updates from organizations
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadOffers();
        _startPolling();
      }
    });
  }

  void _loadOffers() {
    setState(() {
      final userId = UserSession.getCurrentUserId();
      if (userId == null) {
        _submittedOffers = Future.value(<Map<String, dynamic>>[]);
        return;
      }
      
      _submittedOffers = DatabaseHelper.instance.getDonationOffers(
        userId: userId,
        activeOnly: widget.activeOnly,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _submittedOffers,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not fetch donation offers',
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
                    'No donation offers yet!',
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
                return _DonationOfferTile(
                  offer: DonationOffer.fromDatabaseRow(snapshot.data![i]),
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

class _DonationOfferTile extends StatefulWidget {
  final DonationOffer offer;

  const _DonationOfferTile({Key? key, required this.offer}) : super(key: key);

  @override
  _DonationOfferTileState createState() => _DonationOfferTileState();
}

class _DonationOfferTileState extends State<_DonationOfferTile> {
  DonationOffer get offer => widget.offer;

  String _getBloodTypeDisplay(BloodType bloodType) {
    // Use the extension's name getter explicitly
    return BloodTypeUtils.bloodTypes[bloodType.index];
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'green';
      case 'rejected':
        return 'red';
      case 'fulfilled':
        return 'blue';
      case 'pending':
        return 'orange';
      default:
        return 'grey';
    }
  }

  String _getDestinationText() {
    final centerName = offer.destinationCenter?.name ?? 'Not specified';
    switch (offer.destinationType) {
      case DestinationType.hospital:
        return 'Hospital: $centerName';
      case DestinationType.redCross:
        return 'Red Cross: $centerName';
      case DestinationType.bloodBank:
        return 'Blood Bank: $centerName';
      default:
        return 'Destination: $centerName';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(offer.status);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MainColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.droplet,
                    color: MainColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Type: ${_getBloodTypeDisplay(offer.bloodType)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: offer.organizationId != null
                            ? () => _showOrganizationDetails(context, offer.organizationId!)
                            : null,
                        child: Text(
                          _getDestinationText(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: offer.organizationId != null
                                    ? MainColors.primary
                                    : null,
                                decoration: offer.organizationId != null
                                    ? TextDecoration.underline
                                    : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(offer.status) == 'green'
                        ? Colors.green.withOpacity(0.1)
                        : _getStatusColor(offer.status) == 'red'
                            ? Colors.red.withOpacity(0.1)
                            : _getStatusColor(offer.status) == 'blue'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(offer.status) == 'green'
                          ? Colors.green
                          : _getStatusColor(offer.status) == 'red'
                              ? Colors.red
                              : _getStatusColor(offer.status) == 'blue'
                                  ? Colors.blue
                                  : Colors.orange,
                    ),
                  ),
                  child: Text(
                    offer.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(offer.status) == 'green'
                          ? Colors.green
                          : _getStatusColor(offer.status) == 'red'
                              ? Colors.red
                              : _getStatusColor(offer.status) == 'blue'
                                  ? Colors.blue
                                  : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Donation Date: ${Tools.formatDate(offer.donationDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (offer.note != null && offer.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${offer.note}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (offer.organizationResponse != null && offer.organizationResponse!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: offer.status == 'accepted'
                      ? Colors.green.withOpacity(0.1)
                      : offer.status == 'rejected'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: offer.status == 'accepted'
                        ? Colors.green
                        : offer.status == 'rejected'
                            ? Colors.red
                            : Colors.blue,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      offer.status == 'accepted'
                          ? Icons.check_circle
                          : offer.status == 'rejected'
                              ? Icons.cancel
                              : Icons.info,
                      size: 16,
                      color: offer.status == 'accepted'
                          ? Colors.green
                          : offer.status == 'rejected'
                              ? Colors.red
                              : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offer.organizationResponse!,
                        style: TextStyle(
                          fontSize: 12,
                          color: offer.status == 'accepted'
                              ? Colors.green[800]
                              : offer.status == 'rejected'
                                  ? Colors.red[800]
                                  : Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SingleDonationOfferScreen(offer: offer),
                  ),
                );
              },
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Ink(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: MainColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Details',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrganizationDetails(BuildContext context, int organizationId) async {
    // Fetch organization details from database
    final organization = await DatabaseHelper.instance.getUserById(organizationId);
    
    if (organization == null) {
      Fluttertoast.showToast(msg: 'Organization details not found');
      return;
    }

    final orgName = organization['name'] as String? ?? 'Unknown Organization';
    final orgLocation = organization['location'] as String? ?? 'Location not specified';
    final orgPhone = organization['phone_number'] as String?;
    final orgEmail = organization['email'] as String?;
    final orgType = organization['organization_type'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                orgName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MainColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              if (orgType != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    _getOrganizationTypeName(orgType),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildInfoRow(
                context,
                icon: Icons.location_on,
                label: 'Location',
                value: orgLocation,
              ),
              if (orgPhone != null && orgPhone.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.phone,
                  label: 'Phone',
                  value: orgPhone,
                  onTap: () => _makePhoneCall(orgPhone),
                ),
              ],
              if (orgEmail != null && orgEmail.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.email,
                  label: 'Email',
                  value: orgEmail,
                  onTap: () => _sendEmail(orgEmail),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MainColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _getDirections(orgLocation, orgName),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Get Directions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: MainColors.primary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MainColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: MainColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _getOrganizationTypeName(String type) {
    switch (type) {
      case 'hospital':
        return 'Hospital';
      case 'red_cross':
        return 'Red Cross';
      case 'blood_bank':
        return 'Blood Bank';
      default:
        return 'Organization';
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    // Remove any spaces or dashes
    final cleanedPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    final url = Uri.parse('tel:$cleanedPhone');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Fluttertoast.showToast(msg: 'Could not make phone call');
    }
  }

  Future<void> _sendEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Fluttertoast.showToast(msg: 'Could not open email client');
    }
  }

  Future<void> _getDirections(String? location, String orgName) async {
    if (location == null || location.isEmpty) {
      Fluttertoast.showToast(msg: 'Location not available');
      return;
    }

    // Try to extract coordinates if location contains them
    // Format might be "lat,lon" or "Location Name"
    final locationParts = location.split(',');
    double? latitude;
    double? longitude;

    if (locationParts.length == 2) {
      latitude = double.tryParse(locationParts[0].trim());
      longitude = double.tryParse(locationParts[1].trim());
    }

    if (latitude != null && longitude != null) {
      // Use coordinates for navigation
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
      } catch (e) {
        // Try Google Maps directions URL (opens app if installed, browser if not)
        try {
          await launchUrl(googleMapsDirectionsUrl, mode: LaunchMode.externalApplication);
          launched = true;
        } catch (e2) {
          // Try Apple Maps as fallback (for iOS)
          try {
            await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
            launched = true;
          } catch (e3) {
            // All attempts failed
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
      final encodedLocation = Uri.encodeComponent('$orgName $location');
      final googleMapsSearchUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedLocation'
      );

      try {
        await launchUrl(googleMapsSearchUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Could not open maps. Please install Google Maps.',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }
}

