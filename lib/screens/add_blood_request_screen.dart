import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';

import '../common/hive_boxes.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';

import '../data/medical_center.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';
import '../widgets/medical_center_picker.dart';
import '../services/notification_service.dart';

class AddBloodRequestScreen extends StatefulWidget {
  static const route = 'add-request';
  const AddBloodRequestScreen({Key? key}) : super(key: key);

  @override
  _AddBloodRequestScreenState createState() => _AddBloodRequestScreenState();
}

class _AddBloodRequestScreenState extends State<AddBloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _noteController = TextEditingController();
  String _bloodType = 'A+';
  MedicalCenter? _medicalCenter;
  DateTime? _requestDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = await UserSession.getCurrentUser();
    if (user != null) {
      // Allow recipients and hospital organizations - donors and admins cannot request blood
      final userRole = user['user_role'] as String? ?? 'donor';
      final isAdmin = user['is_admin'] == true;
      final isOrganization = userRole == 'organization';
      final organizationType = user['organization_type'] as String?;
      
      final canRequest = (userRole == 'recipient') ||
          (isOrganization && organizationType == 'hospital');

      if (!canRequest || isAdmin) {
        // Donors and admins (and non-hospital orgs) cannot access this screen
        if (mounted) {
          Fluttertoast.showToast(
            msg: isAdmin
                ? 'Admins cannot request blood. Admins manage the system.'
                : 'Only recipients and hospital organizations can request blood',
            toastLength: Toast.LENGTH_LONG,
          );
          Navigator.pop(context);
        }
        return;
      }
    } else {
      // No user logged in
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Please login to access this feature',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _contactNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const elementsSpacer = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Blood Request')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _patientNameField(),
                  elementsSpacer,
                  _contactNumberField(),
                  elementsSpacer,
                  _bloodTypeSelector(),
                  elementsSpacer,
                  _medicalCenterSelector(),
                  elementsSpacer,
                  _requestDatePicker(),
                  elementsSpacer,
                  _noteField(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ActionButton(
                      callback: _submit,
                      text: 'Submit',
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = UserSession.getCurrentUserId();
        if (userId == null) {
          Fluttertoast.showToast(msg: 'Please login to submit a request');
          setState(() => _isLoading = false);
          return;
        }

        if (_medicalCenter == null) {
          Fluttertoast.showToast(msg: 'Please select a medical center');
          setState(() => _isLoading = false);
          return;
        }

        if (_requestDate == null) {
          Fluttertoast.showToast(msg: 'Please select a request date');
          setState(() => _isLoading = false);
          return;
        }

        await DatabaseHelper.instance.createBloodRequest(
          userId: userId,
          patientName: _patientNameController.text,
          bloodType: _bloodType,
          contactNumber: _contactNumberController.text,
          medicalCenter: jsonEncode(_medicalCenter!.toJson()),
          requestDate: _requestDate!,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          // If the requester is an organization, set organization_id
          organizationId: (await UserSession.getCurrentUser())?['user_role'] == 'organization'
              ? userId
              : null,
        );
        // Schedule reminders: day before and morning of the request date at 9 AM
        final dayBefore = DateTime(
          _requestDate!.year, _requestDate!.month, _requestDate!.day - 1, 9, 0,
        );
        if (dayBefore.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleAt(
            when: dayBefore,
            title: 'Blood Request Reminder',
            body: 'Reminder: ${_patientNameController.text} needs blood by ${Tools.formatDate(_requestDate!)}.',
          );
        }
        final morningOf = DateTime(_requestDate!.year, _requestDate!.month, _requestDate!.day, 9, 0);
        if (morningOf.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleAt(
            when: morningOf,
            title: 'Today: Blood Request',
            body: 'Please arrange ${_bloodType} blood for ${_patientNameController.text} today.',
          );
        }
        
        _resetFields();
        Fluttertoast.showToast(msg: 'Request successfully Submitted');
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error submitting request: $e');
        Fluttertoast.showToast(msg: 'Something went wrong. Please try again');
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _patientNameField() => TextFormField(
        controller: _patientNameController,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        validator: (v) => Validators.required(v!, 'Patient name'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Patient Name',
        ),
      );

  Widget _contactNumberField() => TextFormField(
        controller: _contactNumberController,
        keyboardType: TextInputType.phone,
        validator: (v) =>
            Validators.required(v!, 'Contact number') ?? Validators.phone(v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Contact number',
          prefixText: '+254 ',
        ),
      );

  Widget _noteField() => TextFormField(
        controller: _noteController,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Notes (Optional)',
          alignLabelWithHint: true,
        ),
      );

  Widget _bloodTypeSelector() => DropdownButtonFormField<String>(
        value: _bloodType,
        onChanged: (v) => setState(() => _bloodType = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Blood Type',
        ),
        items: BloodTypeUtils.bloodTypes
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
      );

  Widget _medicalCenterSelector() => GestureDetector(
        onTap: () async {
          final picked = await showModalBottomSheet<MedicalCenter>(
            context: context,
            builder: (_) => const Padding(
              padding: EdgeInsets.all(8.0),
              child: MedicalCenterPicker(),
            ),
            isScrollControlled: true,
          );
          if (picked != null) {
            setState(() => _medicalCenter = picked);
          }
        },
        child: AbsorbPointer(
        child: TextFormField(
          key: ValueKey<String?>(_medicalCenter?.name),
          initialValue: _medicalCenter?.name,
          validator: (_) => _medicalCenter == null
              ? '* Please select a medical center'
              : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Medical Center',
            ),
          ),
        ),
      );

  Widget _requestDatePicker() => GestureDetector(
        onTap: () async {
        final today = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: today,
          firstDate: today,
          lastDate: today.add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _requestDate = picked);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          key: ValueKey<DateTime?>(_requestDate),
          initialValue: _requestDate != null ? Tools.formatDate(_requestDate!) : null,
          validator: (_) =>
              _requestDate == null ? '* Please select a date' : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Request date',
              helperText: 'The date on which you need the blood to be ready',
            ),
          ),
        ),
      );

  void _resetFields() {
    _patientNameController.clear();
    _contactNumberController.clear();
    _noteController.clear();
    _requestDate = null;
    _medicalCenter = null;
  }
}
