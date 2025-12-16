import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../utils/blood_types.dart';
import 'medical_center.dart';

enum DestinationType {
  hospital,
  redCross,
  bloodBank,
  recipient,
}

extension DestinationTypeExtension on DestinationType {
  String get name {
    switch (this) {
      case DestinationType.hospital:
        return 'Hospital';
      case DestinationType.redCross:
        return 'Red Cross';
      case DestinationType.bloodBank:
        return 'Blood Bank';
      case DestinationType.recipient:
        return 'Recipient';
    }
  }

  String get databaseValue {
    switch (this) {
      case DestinationType.hospital:
        return 'hospital';
      case DestinationType.redCross:
        return 'red_cross';
      case DestinationType.bloodBank:
        return 'blood_bank';
      case DestinationType.recipient:
        return 'recipient';
    }
  }

  static DestinationType fromString(String value) {
    switch (value) {
      case 'hospital':
        return DestinationType.hospital;
      case 'red_cross':
        return DestinationType.redCross;
      case 'blood_bank':
        return DestinationType.bloodBank;
      case 'recipient':
        return DestinationType.recipient;
      default:
        return DestinationType.hospital;
    }
  }
}

class DonationOffer {
  final String id;
  final int userId;
  final String donorName;
  final String contactNumber;
  final BloodType bloodType;
  final DestinationType destinationType;
  final MedicalCenter? destinationCenter; // For hospital, red cross, blood bank
  final int? recipientUserId; // For recipient type
  final int? organizationId; // For organization type
  final String? organizationResponse; // Response from organization
  final DateTime createdAt;
  final DateTime donationDate;
  final String note;
  final String status;

  DonationOffer({
    required this.id,
    required this.userId,
    required this.donorName,
    required this.contactNumber,
    required this.bloodType,
    required this.destinationType,
    this.destinationCenter,
    this.recipientUserId,
    this.organizationId,
    this.organizationResponse,
    required this.createdAt,
    required this.donationDate,
    required this.note,
    required this.status,
  });

  bool get isFulfilled => status == 'fulfilled';
  bool get isPending => status == 'pending';

  factory DonationOffer.fromJson(Map<String, dynamic> json, {String? id}) {
    final offerId = id ?? json['id'].toString();
    
    // Parse destination center from string or map (if exists)
    MedicalCenter? destinationCenter;
    if (json['destination_center'] != null) {
      try {
        if (json['destination_center'] is String) {
          final centerStr = json['destination_center'] as String;
          try {
            destinationCenter = MedicalCenter.fromJson(
              jsonDecode(centerStr) as Map<String, dynamic>,
            );
          } catch (e) {
            debugPrint('Error parsing destination center JSON: $e');
          }
        } else {
          destinationCenter = MedicalCenter.fromJson(
            json['destination_center'] as Map<String, dynamic>,
          );
        }
      } catch (e) {
        debugPrint('Error parsing destination center: $e');
      }
    }
    
    return DonationOffer(
      id: offerId,
      userId: json['user_id'] as int,
      donorName: json['donor_name'] as String,
      contactNumber: json['contact_number'] as String,
      bloodType: BloodTypeUtils.fromName(json['blood_type'] as String),
      destinationType: DestinationTypeExtension.fromString(
        json['destination_type'] as String,
      ),
      destinationCenter: destinationCenter,
      recipientUserId: json['recipient_user_id'] as int?,
      organizationId: json['organization_id'] as int?,
      organizationResponse: json['organization_response'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      donationDate: DateTime.parse(json['donation_date'] as String),
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  factory DonationOffer.fromDatabaseRow(Map<String, dynamic> row) {
    return DonationOffer.fromJson(row, id: row['id'].toString());
  }
}

