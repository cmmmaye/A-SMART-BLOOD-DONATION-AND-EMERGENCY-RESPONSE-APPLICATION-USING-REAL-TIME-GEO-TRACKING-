import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../data/medical_center.dart';
import '../data/lists/hospitals.dart';
import '../data/lists/lrc_centers.dart';
import '../data/lists/blood_banks.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';

class EditOrganizationScreen extends StatefulWidget {
  final Map<String, dynamic> organization;
  
  const EditOrganizationScreen({Key? key, required this.organization}) : super(key: key);

  @override
  _EditOrganizationScreenState createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends State<EditOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String? _organizationType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadOrganizationData();
  }

  Future<void> _checkAdminAccess() async {
    final user = await UserSession.getCurrentUser();
    if (user == null || user['is_admin'] != true) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Only admins can edit organizations',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context);
      }
    }
  }

  void _loadOrganizationData() {
    final org = widget.organization;
    _nameController.text = org['name'] ?? '';
    _emailController.text = org['email'] ?? '';
    _phoneController.text = org['phone_number'] ?? '';
    _locationController.text = org['location'] ?? '';
    _organizationType = org['organization_type'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_organizationType == null) {
        Fluttertoast.showToast(msg: 'Please select organization type');
        return;
      }

      setState(() => _isLoading = true);

      try {
        await DatabaseHelper.instance.updateUser(
          id: widget.organization['id'] as int,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          organizationType: _organizationType,
          location: _locationController.text.trim(),
        );

        Fluttertoast.showToast(msg: 'Organization updated successfully');
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error updating organization: $e');
        Fluttertoast.showToast(msg: 'Failed to update organization');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Organization')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _nameField(),
                  const SizedBox(height: 16),
                  _emailField(),
                  const SizedBox(height: 16),
                  _phoneField(),
                  const SizedBox(height: 16),
                  _organizationTypeSelector(),
                  const SizedBox(height: 16),
                  _locationField(),
                  const SizedBox(height: 24),
                  ActionButton(
                    callback: _saveChanges,
                    text: 'Save Changes',
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameField() => TextFormField(
        controller: _nameController,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        validator: (v) => Validators.required(v!, 'Organization name'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Organization Name',
          prefixIcon: Icon(FontAwesomeIcons.building),
        ),
      );

  Widget _emailField() => TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: (v) => Validators.required(v!, 'Email'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Email',
          prefixIcon: Icon(FontAwesomeIcons.envelope),
        ),
      );

  Widget _phoneField() => TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Phone Number',
          prefixIcon: Icon(FontAwesomeIcons.phone),
          prefixText: '+254 ',
        ),
      );

  Widget _organizationTypeSelector() => DropdownButtonFormField<String>(
        value: _organizationType,
        onChanged: (v) => setState(() => _organizationType = v),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Organization Type',
          prefixIcon: Icon(FontAwesomeIcons.building),
        ),
        items: const [
          DropdownMenuItem(
            value: 'hospital',
            child: Text('Hospital'),
          ),
          DropdownMenuItem(
            value: 'red_cross',
            child: Text('Red Cross'),
          ),
          DropdownMenuItem(
            value: 'blood_bank',
            child: Text('Blood Bank'),
          ),
        ],
        validator: (v) => v == null ? 'Please select organization type' : null,
      );

  Widget _locationField() => TextFormField(
        controller: _locationController,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        validator: (v) => Validators.required(v!, 'Location'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Location',
          prefixIcon: Icon(FontAwesomeIcons.locationDot),
          helperText: 'City or address of your organization',
        ),
      );
}

