import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/hive_boxes.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../utils/tools.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'organization_dashboard_screen.dart';
import 'login_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  static const route = 'admin-login';
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  String? _emailError, _passError;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainColors.primary,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(IconAssets.logo),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  FontAwesomeIcons.userShield,
                                  color: MainColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin Login',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _emailField(),
                          const SizedBox(height: 18),
                          _passField(),
                          const SizedBox(height: 16),
                          ActionButton(
                            text: 'Login as Admin',
                            callback: _login,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, LoginScreen.route);
                            },
                            child: Text(
                              'Regular User Login',
                              style: TextStyle(color: MainColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailField() => TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        onTap: () => setState(() => _emailError = null),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Admin Email',
          prefixIcon: const Icon(FontAwesomeIcons.envelope),
          errorText: _emailError,
        ),
      );

  Widget _passField() => TextField(
        controller: _passController,
        onTap: () => setState(() => _passError = null),
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          errorText: _passError,
        ),
      );

  Future<void> _login() async {
    if (_validateFields()) {
      setState(() {
        _emailError = null;
        _passError = null;
        _isLoading = true;
      });
      
      final email = _emailController.text.trim();
      final password = _passController.text;
      
      try {
        // Verify password
        final isValid = await DatabaseHelper.instance.verifyPassword(email, password);
        
        if (!isValid) {
          final user = await DatabaseHelper.instance.getUserByEmail(email);
          setState(() {
            _isLoading = false;
            if (user == null) {
              _emailError = 'No user found for that email';
            } else {
              _passError = 'Wrong password provided';
            }
          });
          return;
        }
        
        // Get user data
        final user = await DatabaseHelper.instance.getUserByEmail(email);
        if (user == null) {
          setState(() {
            _isLoading = false;
            _emailError = 'No user found for that email';
          });
          return;
        }
        
        // Check if user is an admin
        if (user['is_admin'] != true) {
          setState(() {
            _isLoading = false;
            _emailError = 'This account is not an admin account';
          });
          Fluttertoast.showToast(
            msg: 'Only admin accounts can login here. Please use regular login.',
            toastLength: Toast.LENGTH_LONG,
          );
          return;
        }
        
        // Save blood type to config
        final configBox = Hive.box(ConfigBox.key);
        configBox.put(ConfigBox.bloodType, user['blood_type'] as String);
        
        // Set current user session
        await UserSession.setCurrentUserId(user['id'] as int);
        
        debugPrint('Admin logged in: ${user['email']}');
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Admins always go to admin dashboard
          Navigator.of(context).pushNamedAndRemoveUntil(
            AdminDashboardScreen.route,
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error logging in: $e');
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again',
        );
      }
    }
  }

  bool _validateFields() {
    setState(() {
      _emailError = Validators.required(_emailController.text, 'Email');
      _passError = Validators.required(_passController.text, 'Password');
    });

    return _emailError == null && _passError == null;
  }
}

