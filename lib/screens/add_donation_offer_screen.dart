import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../data/donation_offer.dart';
import '../data/medical_center.dart';
import '../utils/blood_types.dart';
import '../utils/tools.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';
import '../widgets/medical_center_picker.dart' show MedicalCenterCategory, MedicalCenterPicker;
import '../services/notification_service.dart';

class AddDonationOfferScreen extends StatefulWidget {
  static const route = 'add-donation-offer';
  const AddDonationOfferScreen({Key? key}) : super(key: key);

  @override
  _AddDonationOfferScreenState createState() => _AddDonationOfferScreenState();
}

class _AddDonationOfferScreenState extends State<AddDonationOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _donorNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _noteController = TextEditingController();
  String _bloodType = 'A+';
  DestinationType _destinationType = DestinationType.hospital;
  MedicalCenter? _destinationCenter;
  DateTime? _donationDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await UserSession.getCurrentUser();
    if (user != null) {
      // Check if user is a donor - recipients and admins cannot donate
      final userRole = user['user_role'] as String? ?? 'donor';
      final isAdmin = user['is_admin'] == true;
      
      if (userRole != 'donor' || isAdmin) {
        // Recipients and admins cannot access this screen
        if (mounted) {
          Fluttertoast.showToast(
            msg: isAdmin
                ? 'Admins cannot donate blood. Admins manage the system.'
                : 'Recipients cannot donate blood',
            toastLength: Toast.LENGTH_LONG,
          );
          Navigator.pop(context);
        }
        return;
      }
      
      setState(() {
        _donorNameController.text = user['name'] ?? '';
        _contactNumberController.text = user['phone_number'] ?? '';
        _bloodType = user['blood_type'] ?? 'A+';
      });
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
    _donorNameController.dispose();
    _contactNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const elementsSpacer = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: const Text('Offer to Donate Blood')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _donorNameField(),
                  elementsSpacer,
                  _contactNumberField(),
                  elementsSpacer,
                  _bloodTypeSelector(),
                  elementsSpacer,
                  _destinationTypeSelector(),
                  elementsSpacer,
                  _destinationCenterSelector(),
                  elementsSpacer,
                  _donationDatePicker(),
                  elementsSpacer,
                  _noteField(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ActionButton(
                      callback: _submit,
                      text: 'Submit Offer',
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
          Fluttertoast.showToast(msg: 'Please login to submit an offer');
          setState(() => _isLoading = false);
          return;
        }

        if (_donationDate == null) {
          Fluttertoast.showToast(msg: 'Please select a donation date');
          setState(() => _isLoading = false);
          return;
        }

        // Validate destination - must select a medical center
        if (_destinationCenter == null) {
          Fluttertoast.showToast(
            msg: 'Please select a ${_destinationType.name}',
          );
          setState(() => _isLoading = false);
          return;
        }

        await DatabaseHelper.instance.createDonationOffer(
          userId: userId,
          donorName: _donorNameController.text,
          bloodType: _bloodType,
          contactNumber: _contactNumberController.text,
          destinationType: _destinationType.databaseValue,
          destinationCenter: jsonEncode(_destinationCenter!.toJson()),
          recipientUserId: null, // Donors can only donate to medical centers, not recipients
          donationDate: _donationDate!,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );

        // Schedule reminders: day before and morning of donation at 9 AM
        final dayBefore = DateTime(
          _donationDate!.year, _donationDate!.month, _donationDate!.day - 1, 9, 0,
        );
        if (dayBefore.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleAt(
            when: dayBefore,
            title: 'Donation Reminder',
            body: 'Reminder: ${_donorNameController.text}, your donation is on ${Tools.formatDate(_donationDate!)}.',
          );
        }
        final morningOf = DateTime(_donationDate!.year, _donationDate!.month, _donationDate!.day, 9, 0);
        if (morningOf.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleAt(
            when: morningOf,
            title: 'Today: Donation Day',
            body: 'Your blood donation is scheduled for today. Thank you!',
          );
        }

        _resetFields();
        Fluttertoast.showToast(msg: 'Donation offer successfully submitted');
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error submitting offer: $e');
        Fluttertoast.showToast(msg: 'Something went wrong. Please try again');
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _donorNameField() => TextFormField(
        controller: _donorNameController,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        validator: (v) => Validators.required(v!, 'Donor name'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Donor Name',
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

  Widget _destinationTypeSelector() => DropdownButtonFormField<DestinationType>(
        value: _destinationType,
        onChanged: (v) {
          setState(() {
            _destinationType = v!;
            // Clear selections when changing destination type
            _destinationCenter = null;
          });
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Donate To',
          helperText: 'Select where you want to donate',
        ),
        items: DestinationType.values
            .where((v) => v != DestinationType.recipient) // Exclude recipient option
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v.name),
                ))
            .toList(),
      );

  Widget _destinationCenterSelector() {
    // Determine which category to show based on destination type
    MedicalCenterCategory? category;
    if (_destinationType == DestinationType.hospital) {
      category = MedicalCenterCategory.hospitals;
    } else if (_destinationType == DestinationType.redCross) {
      category = MedicalCenterCategory.lrcCenters;
    } else if (_destinationType == DestinationType.bloodBank) {
      category = MedicalCenterCategory.bloodBanks;
    }

    return GestureDetector(
      onTap: () async {
        final picked = await showModalBottomSheet<MedicalCenter>(
          context: context,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: MedicalCenterPicker(
              initialCategory: category,
            ),
          ),
          isScrollControlled: true,
        );
        if (picked != null) {
          setState(() => _destinationCenter = picked);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          key: ValueKey<String?>(_destinationCenter?.name),
          initialValue: _destinationCenter?.name,
          validator: (_) => _destinationCenter == null
              ? '* Please select a ${_destinationType.name}'
              : null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _destinationType.name,
          ),
        ),
      ),
    );
  }


  Widget _donationDatePicker() => GestureDetector(
        onTap: () async {
          final today = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: today,
            firstDate: today,
            lastDate: today.add(const Duration(days: 365)),
          );
          if (picked != null) {
            setState(() => _donationDate = picked);
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            key: ValueKey<DateTime?>(_donationDate),
            initialValue:
                _donationDate != null ? Tools.formatDate(_donationDate!) : null,
            validator: (_) =>
                _donationDate == null ? '* Please select a date' : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Donation date',
              helperText: 'The date on which you want to donate',
            ),
          ),
        ),
      );

  void _resetFields() {
    _donorNameController.clear();
    _contactNumberController.clear();
    _noteController.clear();
    _donationDate = null;
    _destinationCenter = null;
    _loadUserData(); // Reload user data
  }
}

