import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../utils/blood_types.dart';
import 'medical_center.dart';

class BloodRequest {
  final String id;
  final int userId;
  final String patientName, contactNumber, note;
  final BloodType bloodType;
  final DateTime createdAt, requestDate;
  final MedicalCenter medicalCenter;
  final String status;
  final int? organizationId;
  final String? organizationResponse;

  BloodRequest({
    required this.id,
    required this.userId,
    required this.patientName,
    required this.contactNumber,
    required this.bloodType,
    required this.medicalCenter,
    required this.createdAt,
    required this.requestDate,
    required this.note,
    required this.status,
    this.organizationId,
    this.organizationResponse,
  });

  bool get isFulfilled => status == 'fulfilled';

  factory BloodRequest.fromJson(Map<String, dynamic> json, {String? id}) {
    final requestId = id ?? json['id'].toString();
    
    // Parse medical center from string or map
    MedicalCenter medicalCenter;
    try {
      if (json['medical_center'] is String) {
        final medicalCenterStr = json['medical_center'] as String;
        try {
          // Try to parse as JSON first (new format)
          medicalCenter = MedicalCenter.fromJson(
            jsonDecode(medicalCenterStr) as Map<String, dynamic>,
          );
        } catch (e) {
          // If JSON decode fails, it might be old format or corrupted data
          // Create a default medical center as fallback
          debugPrint('Error parsing medical center JSON: $e');
          debugPrint('Medical center string: $medicalCenterStr');
          medicalCenter = const MedicalCenter(
            name: 'Unknown Medical Center',
            phoneNumbers: [],
            location: 'Unknown',
            latitude: '0',
            longitude: '0',
          );
        }
      } else {
        medicalCenter = MedicalCenter.fromJson(
          json['medical_center'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Error parsing medical center: $e');
      // Fallback to default medical center
      medicalCenter = const MedicalCenter(
        name: 'Unknown Medical Center',
        phoneNumbers: [],
        location: 'Unknown',
        latitude: '0',
        longitude: '0',
      );
    }
    
    return BloodRequest(
      id: requestId,
      userId: json['user_id'] as int,
      patientName: json['patient_name'] as String,
      contactNumber: json['contact_number'] as String,
      bloodType: BloodTypeUtils.fromName(json['blood_type'] as String),
      medicalCenter: medicalCenter,
      createdAt: DateTime.parse(json['created_at'] as String),
      requestDate: DateTime.parse(json['request_date'] as String),
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      organizationId: json['organization_id'] as int?,
      organizationResponse: json['organization_response'] as String?,
    );
  }

  factory BloodRequest.fromDatabaseRow(Map<String, dynamic> row) {
    return BloodRequest.fromJson(row, id: row['id'].toString());
  }
}
