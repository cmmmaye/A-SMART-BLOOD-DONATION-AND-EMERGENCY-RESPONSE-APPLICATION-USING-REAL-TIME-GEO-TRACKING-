import 'package:flutter/material.dart';

import '../common/colors.dart';
import '../data/blood_request.dart';
import '../screens/single_request_screen.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';

const kBorderRadius = 12.0;

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

class BloodRequestTile extends StatelessWidget {
  final BloodRequest request;

  const BloodRequestTile({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient Name', style: textTheme.bodySmall),
                      Text(request.patientName),
                      const SizedBox(height: 12),
                      Text('Location', style: textTheme.bodySmall),
                      Text(
                        '${request.medicalCenter.name} - ${request.medicalCenter.location}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Needed By', style: textTheme.bodySmall),
                    Text(Tools.formatDate(request.requestDate)),
                    const SizedBox(height: 12),
                    Text('Blood Type', style: textTheme.bodySmall),
                    Text(request.bloodType.name),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getStatusColor(request.status)),
                      ),
                      child: Text(
                        request.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(request.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (request.organizationResponse != null && request.organizationResponse!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: request.status == 'accepted'
                      ? Colors.green.withOpacity(0.1)
                      : request.status == 'rejected'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: request.status == 'accepted'
                        ? Colors.green
                        : request.status == 'rejected'
                            ? Colors.red
                            : Colors.blue,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      request.status == 'accepted'
                          ? Icons.check_circle
                          : request.status == 'rejected'
                              ? Icons.cancel
                              : Icons.info,
                      size: 16,
                      color: request.status == 'accepted'
                          ? Colors.green
                          : request.status == 'rejected'
                              ? Colors.red
                              : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.organizationResponse!,
                        style: TextStyle(
                          fontSize: 12,
                          color: request.status == 'accepted'
                              ? Colors.green[800]
                              : request.status == 'rejected'
                                  ? Colors.red[800]
                                  : Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          InkWell(
            onTap: () async {
              // Navigate to details screen and wait for result
              // If request was marked as fulfilled, the parent lists will auto-refresh
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SingleRequestScreen(request: request),
              ));
            },
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(kBorderRadius),
              bottomLeft: Radius.circular(kBorderRadius),
            ),
            child: Ink(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: MainColors.primary,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(kBorderRadius),
                  bottomLeft: Radius.circular(kBorderRadius),
                ),
              ),
              child: Center(
                child: Text(
                  'Details',
                  style: textTheme.labelLarge!.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
