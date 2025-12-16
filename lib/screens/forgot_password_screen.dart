import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../database/database_helper.dart';
import '../services/otp_service.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const route = 'forgot-password';
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _emailError, _otpError, _passwordError, _confirmPasswordError;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  bool _isLoading = false;
  bool _showOtpStep = false;
  bool _showResetStep = false;
  String _generatedOtp = '';
  int? _userId;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(IconAssets.logo),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _showResetStep
                              ? 'Reset Password'
                              : _showOtpStep
                                  ? 'Verify Email'
                                  : 'Forgot Password',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_showResetStep)
                        _resetPasswordStep()
                      else if (_showOtpStep)
                        _otpStep()
                      else
                        _emailStep(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailStep() => Column(
        children: [
          Text(
            'Enter your email address and we\'ll send you a verification code to reset your password.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          _emailField(),
          const SizedBox(height: 32),
          ActionButton(
            text: 'Send Code',
            callback: _sendVerificationCode,
            isLoading: _isLoading,
          ),
        ],
      );

  Widget _otpStep() => Column(
        children: [
          Text(
            'We sent a verification code to',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _emailController.text.trim(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: MainColors.primary,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _otpField(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Didn\'t receive code?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: _resendOtp,
                child: const Text('Resend'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showOtpStep = false;
                      _otpController.clear();
                      _otpError = null;
                    });
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ActionButton(
                  text: 'Verify',
                  callback: _verifyOtp,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _resetPasswordStep() => Column(
        children: [
          _newPasswordField(),
          const SizedBox(height: 18),
          _confirmPasswordField(),
          const SizedBox(height: 32),
          ActionButton(
            text: 'Reset Password',
            callback: _resetPassword,
            isLoading: _isLoading,
          ),
        ],
      );

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

  Widget _otpField() => TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Enter OTP',
          prefixIcon: const Icon(Icons.password),
          errorText: _otpError,
          hintText: '000000',
        ),
        onTap: () => setState(() => _otpError = null),
      );

  Widget _newPasswordField() => TextField(
        controller: _newPasswordController,
        obscureText: _obscureNewPassword,
        onTap: () => setState(() => _passwordError = null),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'New Password',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            },
          ),
          errorText: _passwordError,
        ),
      );

  Widget _confirmPasswordField() => TextField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        onTap: () => setState(() => _confirmPasswordError = null),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Confirm New Password',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
          ),
          errorText: _confirmPasswordError,
        ),
      );

  Future<void> _sendVerificationCode() async {
    if (_validateEmail()) {
      setState(() {
        _emailError = null;
        _isLoading = true;
      });

      final email = _emailController.text.trim();

      try {
        // Local OTP method
        // Check if user exists
        final user = await DatabaseHelper.instance.getUserByEmail(email);
        if (user == null) {
          setState(() {
            _isLoading = false;
            _emailError = 'No user found with this email';
          });
          return;
        }

        _userId = user['id'] as int;

        // Generate OTP
        await _sendOtp(email);

        // Show OTP verification step
        setState(() {
          _isLoading = false;
          _showOtpStep = true;
        });
      } catch (e) {
        debugPrint('Error sending verification code: $e');
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  Future<void> _sendOtp(String email) async {
    // Generate OTP
    final otp = OtpService.generateOtp();
    _generatedOtp = otp;

    // Get user's phone number if available
    final user = await DatabaseHelper.instance.getUserByEmail(email);
    String? phoneNumber;
    if (user != null) {
      phoneNumber = user['phone_number'] as String?;
    }

    // Send OTP via email (or SMS as fallback)
    final sent = await OtpService.sendOtp(email, phoneNumber, otp);
    
    if (mounted) {
      if (sent) {
        Fluttertoast.showToast(
          msg: 'Verification code sent to your email${phoneNumber != null ? ' or phone' : ''}',
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        // Fallback: Show dialog if email/SMS couldn't be sent
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          title: 'Could not send code automatically',
          desc: 'Please check your email or phone for the verification code.\n\nVerification Code: $otp',
          btnOkOnPress: () {
            Clipboard.setData(ClipboardData(text: otp));
            Fluttertoast.showToast(
              msg: 'OTP copied to clipboard',
              toastLength: Toast.LENGTH_SHORT,
            );
          },
          btnOkText: 'Copy Code',
        ).show();
      }
    }
  }

  Future<void> _resendOtp() async {
    await _sendOtp(_emailController.text.trim());
    Fluttertoast.showToast(
      msg: 'OTP resent successfully',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> _verifyOtp() async {
    if (_validateOtp()) {
      setState(() {
        _otpError = null;
        _showOtpStep = false;
        _showResetStep = true;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_validatePasswords()) {
      setState(() {
        _passwordError = null;
        _confirmPasswordError = null;
        _isLoading = true;
      });

      try {
        // Get user to verify they still exist
        final user = await DatabaseHelper.instance.getUserById(_userId!);
        if (user == null) {
          setState(() => _isLoading = false);
          Fluttertoast.showToast(
            msg: 'User not found. Please try again',
            toastLength: Toast.LENGTH_LONG,
          );
          return;
        }

        // Update password in database
        final bytes = utf8.encode(_newPasswordController.text);
        final hash = sha256.convert(bytes);
        final passwordHash = hash.toString();

        await DatabaseHelper.instance.updateUserPassword(_userId!, passwordHash);

        if (mounted) {
          setState(() => _isLoading = false);
          Fluttertoast.showToast(
            msg: 'Password reset successfully! Please login with your new password',
            toastLength: Toast.LENGTH_LONG,
          );

          // Navigate back to login
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Error resetting password: $e');
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  bool _validateEmail() {
    setState(() {
      _emailError = Validators.required(_emailController.text, 'Email') ??
          Validators.email(_emailController.text);
    });

    return _emailError == null;
  }

  bool _validateOtp() {
    setState(() {
      _otpError = Validators.required(_otpController.text, 'OTP');

      if (_otpError == null) {
        if (_otpController.text != _generatedOtp) {
          _otpError = 'Invalid OTP';
        }
      }
    });

    return _otpError == null;
  }

  bool _validatePasswords() {
    setState(() {
      _passwordError = Validators.required(_newPasswordController.text, 'New Password');
      _confirmPasswordError = Validators.required(_confirmPasswordController.text, 'Confirm Password');

      // Check if passwords match
      if (_passwordError == null && _confirmPasswordError == null) {
        if (_newPasswordController.text != _confirmPasswordController.text) {
          _confirmPasswordError = 'Passwords do not match';
        }
      }
    });

    return _passwordError == null && _confirmPasswordError == null;
  }
}

