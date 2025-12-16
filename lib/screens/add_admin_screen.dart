import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';

class AddAdminScreen extends StatefulWidget {
  static const route = 'add-admin';
  const AddAdminScreen({Key? key}) : super(key: key);

  @override
  _AddAdminScreenState createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
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
          msg: 'Only admins can add other admins',
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

        // Create admin account
        await DatabaseHelper.instance.createUser(
          email: email,
          password: password,
          name: name,
          phoneNumber: phone.isEmpty ? null : phone,
          bloodType: 'A+',
          userRole: 'admin', // Admin is a separate role, not donor/recipient
          isAdmin: true, // This is the key - set admin status
        );

        Fluttertoast.showToast(msg: 'Admin account created successfully!');
        
        // Reset form
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _phoneController.clear();
      } catch (e) {
        debugPrint('Error creating admin: $e');
        Fluttertoast.showToast(msg: 'Failed to create admin account');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Admin')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Create a new admin account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Admins can add organizations and manage news',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _nameField(),
                  const SizedBox(height: 16),
                  _emailField(),
                  const SizedBox(height: 16),
                  _passwordField(),
                  const SizedBox(height: 16),
                  _phoneField(),
                  const SizedBox(height: 24),
                  ActionButton(
                    callback: _submit,
                    text: 'Create Admin Account',
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
        validator: (v) => Validators.required(v!, 'Name'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Admin Name',
          prefixIcon: Icon(FontAwesomeIcons.user),
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
          helperText: 'Password for admin login',
        ),
      );

  Widget _phoneField() => TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Phone Number (Optional)',
          prefixIcon: Icon(FontAwesomeIcons.phone),
          prefixText: '+254 ',
        ),
      );
}

