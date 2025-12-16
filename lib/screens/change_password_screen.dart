import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  static const route = 'change-password';
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserSession.getCurrentUser();
    setState(() => _user = user);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _currentPasswordField(),
                  const SizedBox(height: 16),
                  _newPasswordField(),
                  const SizedBox(height: 16),
                  _confirmPasswordField(),
                  const SizedBox(height: 24),
                  ActionButton(
                    callback: _changePassword,
                    text: 'Update Password',
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

  Widget _currentPasswordField() => TextFormField(
        controller: _currentPasswordController,
        obscureText: _obscureCurrent,
        validator: (v) => Validators.required(v!, 'Current password'),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Current Password',
          prefixIcon: const Icon(FontAwesomeIcons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
        ),
      );

  Widget _newPasswordField() => TextFormField(
        controller: _newPasswordController,
        obscureText: _obscureNew,
        validator: (v) => Validators.required(v!, 'New password'),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'New Password',
          prefixIcon: const Icon(FontAwesomeIcons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
      );

  Widget _confirmPasswordField() => TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirm,
        validator: (v) {
          final base = Validators.required(v!, 'Confirm password');
          if (base != null) return base;
          if (v != _newPasswordController.text) return 'Passwords do not match';
          return null;
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Confirm New Password',
          prefixIcon: const Icon(FontAwesomeIcons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      );

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = UserSession.getCurrentUserId();
    final email = _user?['email'] as String?;
    if (userId == null || email == null) {
      Fluttertoast.showToast(msg: 'Please login again');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Verify current password (for local accounts)
      final isValid = await DatabaseHelper.instance.verifyPassword(
        email,
        _currentPasswordController.text,
      );
      if (!isValid) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: 'Current password is incorrect');
        return;
      }

      // Hash and update
      final bytes = utf8.encode(_newPasswordController.text);
      final hash = sha256.convert(bytes);
      await DatabaseHelper.instance.updateUserPassword(userId, hash.toString());

      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Password updated successfully');
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Failed to update password');
    }
  }
}


