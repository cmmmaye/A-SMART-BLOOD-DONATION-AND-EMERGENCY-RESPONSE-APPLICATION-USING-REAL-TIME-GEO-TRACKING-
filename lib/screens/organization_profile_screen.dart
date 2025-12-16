import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';
import '../widgets/custom_drawer.dart';

class OrganizationProfileScreen extends StatefulWidget {
  static const route = 'organization-profile';
  const OrganizationProfileScreen({Key? key}) : super(key: key);

  @override
  _OrganizationProfileScreenState createState() => _OrganizationProfileScreenState();
}

class _OrganizationProfileScreenState extends State<OrganizationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String? _organizationType;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  // Organizations cannot edit details once created by admin
  final bool _readOnly = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await UserSession.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone_number'] ?? '';
        _locationController.text = user['location'] ?? '';
        _organizationType = user['organization_type'] as String?;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userId = UserSession.getCurrentUserId();
        if (userId == null) {
          Fluttertoast.showToast(msg: 'Please login');
          setState(() => _isLoading = false);
          return;
        }

        if (_organizationType == null) {
          Fluttertoast.showToast(msg: 'Please select organization type');
          setState(() => _isLoading = false);
          return;
        }

        await DatabaseHelper.instance.updateUser(
          id: userId,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          organizationType: _organizationType,
          location: _locationController.text.trim(),
        );

        Fluttertoast.showToast(msg: 'Profile updated successfully');
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error updating profile: $e');
        Fluttertoast.showToast(msg: 'Failed to update profile');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(title: const Text('Organization Profile')),
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
                  if (_readOnly) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'These details are managed by the administrator. Contact admin to request changes.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    ActionButton(
                      callback: _saveProfile,
                      text: 'Save Changes',
                      isLoading: _isLoading,
                    ),
                  ],
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
        readOnly: _readOnly,
        enabled: !_readOnly ? true : false,
        validator: _readOnly ? null : (v) => Validators.required(v!, 'Organization name'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Organization Name',
          prefixIcon: Icon(Icons.business),
        ),
      );

  Widget _emailField() => TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        readOnly: _readOnly,
        enabled: !_readOnly ? true : false,
        validator: _readOnly ? null : (v) => Validators.required(v!, 'Email'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Email',
          prefixIcon: Icon(Icons.email),
        ),
      );

  Widget _phoneField() => TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        readOnly: _readOnly,
        enabled: !_readOnly ? true : false,
        validator: _readOnly ? null : (v) => Validators.required(v!, 'Phone number'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Phone Number',
          prefixIcon: Icon(Icons.phone),
          prefixText: '+254 ',
        ),
      );

  Widget _organizationTypeSelector() => DropdownButtonFormField<String>(
        value: _organizationType,
        onChanged: _readOnly ? null : (v) => setState(() => _organizationType = v),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Organization Type',
          prefixIcon: Icon(Icons.business_center),
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
        validator: _readOnly ? null : (v) => v == null ? 'Please select organization type' : null,
      );

  Widget _locationField() => TextFormField(
        controller: _locationController,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        readOnly: _readOnly,
        enabled: !_readOnly ? true : false,
        validator: _readOnly ? null : (v) => Validators.required(v!, 'Location'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Location',
          prefixIcon: Icon(Icons.location_on),
          helperText: 'City or address of your organization',
        ),
      );
}

