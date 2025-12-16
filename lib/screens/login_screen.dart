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
import 'admin_login_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'organization_dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = 'login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
                            child: Text(
                              'Login',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _emailField(),
                          const SizedBox(height: 18),
                          _passField(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                'Forgot Password?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: MainColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ActionButton(
                            text: 'Login',
                            callback: _login,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, RegistrationScreen.route);
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: 'New user? ',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            children: [
                              TextSpan(
                                text: 'Create Account',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AdminLoginScreen.route);
                        },
                        icon: const Icon(
                          FontAwesomeIcons.userShield,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'Admin Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
          labelText: 'Email',
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
        // Use SQLite authentication
        final isValid = await DatabaseHelper.instance.verifyPassword(email, password);
        
        if (!isValid) {
          final localUser = await DatabaseHelper.instance.getUserByEmail(email);
          setState(() {
            _isLoading = false;
            if (localUser == null) {
              _emailError = 'No user found for that email';
            } else {
              _passError = 'Wrong password provided for that user';
            }
          });
          return;
        }
        
        final user = await DatabaseHelper.instance.getUserByEmail(email);
        
        if (user == null) {
          setState(() {
            _isLoading = false;
            _emailError = 'No user found for that email';
          });
          return;
        }
        
        // Save blood type to config
        final configBox = Hive.box(ConfigBox.key);
        configBox.put(ConfigBox.bloodType, user['blood_type'] as String);
        
        // Set current user session
        await UserSession.setCurrentUserId(user['id'] as int);
        
        debugPrint('User logged in: ${user['email']}');
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Navigate based on user role
          final userRole = user['user_role'] as String? ?? 'donor';
          final destination = userRole == 'organization' 
              ? OrganizationDashboardScreen.route 
              : HomeScreen.route;
          Navigator.of(context).pushNamedAndRemoveUntil(
            destination,
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

  Future<void> _resetPassword() async {
    Navigator.pushNamed(context, ForgotPasswordScreen.route);
  }

  bool _validateFields() {
    setState(() {
      _emailError = Validators.required(_emailController.text, 'Email');
      _passError = Validators.required(_passController.text, 'Password');
    });

    return _emailError == null && _passError == null;
  }
}
