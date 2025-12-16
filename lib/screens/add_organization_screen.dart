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

class AddOrganizationScreen extends StatefulWidget {
  static const route = 'add-organization';
  const AddOrganizationScreen({Key? key}) : super(key: key);

  @override
  _AddOrganizationScreenState createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _organizationType; // 'hospital', 'red_cross', or 'blood_bank'
  MedicalCenter? _selectedMedicalCenter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = await UserSession.getCurrentUser();
    if (user == null || user['is_admin'] != true) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Only admins can add organizations',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_organizationType == null) {
        Fluttertoast.showToast(msg: 'Please select organization type');
        return;
      }
      if (_selectedMedicalCenter == null) {
        Fluttertoast.showToast(msg: 'Please select an organization from the list');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();

        // Check if email already exists
        final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
        if (existingUser != null) {
          setState(() => _isLoading = false);
          Fluttertoast.showToast(msg: 'An account already exists for that email');
          return;
        }

        // Create organization account
        await DatabaseHelper.instance.createUser(
          email: email,
          password: password,
          name: name,
          phoneNumber: phone.isEmpty ? null : phone,
          bloodType: 'A+',
          userRole: 'organization',
          isAdmin: false,
          organizationType: _organizationType,
          location: _selectedMedicalCenter!.location,
        );

        Fluttertoast.showToast(msg: 'Organization account created successfully!');
        
        // Reset form
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _phoneController.clear();
        setState(() {
          _organizationType = null;
          _selectedMedicalCenter = null;
        });
      } catch (e) {
        debugPrint('Error creating organization: $e');
        Fluttertoast.showToast(msg: 'Failed to create organization account');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Organization')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _emailField(),
                  const SizedBox(height: 16),
                  _passwordField(),
                  const SizedBox(height: 16),
                  _organizationTypeSelector(),
                  if (_organizationType != null) ...[
                    const SizedBox(height: 16),
                    _medicalCenterSelector(),
                  ],
                  if (_selectedMedicalCenter != null) ...[
                    const SizedBox(height: 16),
                    _nameField(),
                    const SizedBox(height: 16),
                    _phoneField(),
                  ],
                  const SizedBox(height: 24),
                  ActionButton(
                    callback: _submit,
                    text: 'Create Organization Account',
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
        readOnly: true,
        validator: (v) => Validators.required(v!, 'Organization name'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Organization Name',
          prefixIcon: Icon(FontAwesomeIcons.building),
          helperText: 'Auto-filled from selected organization',
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

  Widget _passwordField() => TextFormField(
        controller: _passwordController,
        obscureText: true,
        validator: (v) => Validators.required(v!, 'Password'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Password',
          prefixIcon: Icon(FontAwesomeIcons.lock),
          helperText: 'Password for organization login',
        ),
      );

  Widget _phoneField() => TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        readOnly: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Phone Number',
          prefixIcon: Icon(FontAwesomeIcons.phone),
          prefixText: '+254 ',
          helperText: 'Auto-filled from selected organization',
        ),
      );

  Widget _organizationTypeSelector() => DropdownButtonFormField<String>(
        value: _organizationType,
        onChanged: (v) {
          setState(() {
            _organizationType = v;
            _selectedMedicalCenter = null; // Clear selection when type changes
            _nameController.clear(); // Clear name when type changes
            _phoneController.clear(); // Clear phone when type changes
          });
        },
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

  Widget _medicalCenterSelector() {
    List<MedicalCenter> centers;
    String label;
    
    switch (_organizationType) {
      case 'hospital':
        centers = hospitals;
        label = 'Select Hospital';
        break;
      case 'red_cross':
        centers = lrcCenters;
        label = 'Select Red Cross Center';
        break;
      case 'blood_bank':
        centers = bloodBanks;
        label = 'Select Blood Bank';
        break;
      default:
        centers = [];
        label = 'Select Organization';
    }

    return GestureDetector(
      onTap: () async {
        if (_organizationType == null) {
          Fluttertoast.showToast(
            msg: 'Please select organization type first',
            toastLength: Toast.LENGTH_SHORT,
          );
          return;
        }

        final picked = await showModalBottomSheet<MedicalCenter>(
          context: context,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: _MedicalCenterPicker(centers: centers),
          ),
          isScrollControlled: true,
        );
        if (picked != null) {
          setState(() {
            _selectedMedicalCenter = picked;
            // Auto-fill name
            _nameController.text = picked.name;
            // Auto-fill phone number if available
            if (picked.phoneNumbers.isNotEmpty) {
              String phoneNumber = picked.phoneNumbers.first;
              if (phoneNumber.startsWith('+254')) {
                phoneNumber = phoneNumber.substring(4);
              } else if (phoneNumber.startsWith('254')) {
                phoneNumber = phoneNumber.substring(3);
              }
              phoneNumber = phoneNumber.replaceFirst(RegExp(r'^0+'), '');
              _phoneController.text = phoneNumber;
            } else {
              _phoneController.clear();
            }
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          key: ValueKey<String?>(_selectedMedicalCenter?.name),
          initialValue: _selectedMedicalCenter?.name,
          validator: (_) => _selectedMedicalCenter == null
              ? 'Please select a ${_organizationType == 'hospital' ? 'hospital' : _organizationType == 'red_cross' ? 'Red Cross center' : 'blood bank'}'
              : null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: label,
            prefixIcon: const Icon(FontAwesomeIcons.locationDot),
            helperText: _selectedMedicalCenter != null
                ? 'Location: ${_selectedMedicalCenter!.location}'
                : 'Tap to select from existing ${_organizationType == 'hospital' ? 'hospitals' : _organizationType == 'red_cross' ? 'Red Cross centers' : 'blood banks'}',
            suffixIcon: _selectedMedicalCenter != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _selectedMedicalCenter = null),
                  )
                : const Icon(Icons.arrow_drop_down),
          ),
        ),
      ),
    );
  }
}

// Medical Center Picker for Admin
class _MedicalCenterPicker extends StatefulWidget {
  final List<MedicalCenter> centers;

  const _MedicalCenterPicker({Key? key, required this.centers}) : super(key: key);

  @override
  _MedicalCenterPickerState createState() => _MedicalCenterPickerState();
}

class _MedicalCenterPickerState extends State<_MedicalCenterPicker> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.centers
        .where((c) =>
            c.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            c.location
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or location',
                  isDense: true,
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No organizations found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        title: Text(
                          filtered[i].name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          filtered[i].location,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .color),
                        ),
                        trailing: filtered[i].phoneNumbers.isNotEmpty
                            ? Text(
                                filtered[i].phoneNumbers.first,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context, filtered[i]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

