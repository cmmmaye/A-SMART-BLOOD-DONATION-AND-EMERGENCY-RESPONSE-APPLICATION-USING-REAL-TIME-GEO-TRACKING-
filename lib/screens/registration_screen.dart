import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../common/assets.dart';
import '../common/colors.dart';
import '../common/hive_boxes.dart';
import '../database/database_helper.dart';
import '../database/user_session.dart';
import '../services/otp_service.dart';
import '../utils/blood_types.dart';
import '../utils/validators.dart';
import '../widgets/action_button.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  static const route = 'register';
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _nameError, _emailError, _passError, _confirmPassError, _phoneError, _otpError;
  String _bloodType = 'A+';
  String _userRole = 'donor'; // 'donor' or 'recipient'
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showOtpStep = false;
  String _generatedOtp = '';
  String _otpMethod = 'phone'; // 'phone' or 'email'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
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
                              _showOtpStep ? 'Verify Phone Number' : 'Register',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_showOtpStep)
                            _otpVerificationStep()
                          else
                            _registrationForm(),
                        ],
                      ),
                    ),
                  ),
                  if (!_showOtpStep)
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, LoginScreen.route);
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
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

  Widget _nameField() => TextField(
        controller: _nameController,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        onTap: () => setState(() => _nameError = null),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Name',
          prefixIcon: const Icon(FontAwesomeIcons.user),
          errorText: _nameError,
        ),
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

  Widget _confirmPassField() => TextField(
        controller: _confirmPassController,
        onTap: () => setState(() => _confirmPassError = null),
        obscureText: _obscureConfirmPassword,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Confirm Password',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
          ),
          errorText: _confirmPassError,
        ),
      );

  Widget _phoneField() => TextField(
        controller: _phoneController,
        onTap: () => setState(() => _phoneError = null),
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Phone Number',
          prefixIcon: const Icon(FontAwesomeIcons.phone),
          prefixText: '+254 ',
          errorText: _phoneError,
        ),
      );

  Widget _bloodTypeSelector() => DropdownButtonFormField<String>(
        value: _bloodType,
        onChanged: (v) => setState(() => _bloodType = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Blood Type',
          prefixIcon: const Icon(FontAwesomeIcons.droplet),
        ),
        items: BloodTypeUtils.bloodTypes
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v),
                ))
            .toList(),
      );

  Widget _userRoleSelector() => DropdownButtonFormField<String>(
        value: _userRole,
        onChanged: (v) => setState(() => _userRole = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'I am a',
          prefixIcon: Icon(FontAwesomeIcons.userGroup),
        ),
        items: const [
          DropdownMenuItem(
            value: 'donor',
            child: Text('Donor'),
          ),
          DropdownMenuItem(
            value: 'recipient',
            child: Text('Recipient'),
          ),
        ],
      );

  Widget _registrationForm() => Column(
        children: [
          _nameField(),
          const SizedBox(height: 18),
          _emailField(),
          const SizedBox(height: 18),
          _passField(),
          const SizedBox(height: 18),
          _confirmPassField(),
          const SizedBox(height: 18),
          _phoneField(),
          const SizedBox(height: 18),
          _bloodTypeSelector(),
          const SizedBox(height: 18),
          _userRoleSelector(),
          const SizedBox(height: 32),
          ActionButton(
            text: 'Register',
            callback: _register,
            isLoading: _isLoading,
          ),
        ],
      );

  Widget _otpVerificationStep() => Column(
        children: [
          Text(
            'We sent a verification code to',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _otpMethod == 'phone'
                ? '+254${_phoneController.text}'
                : _emailController.text.trim(),
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
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _otpMethod = _otpMethod == 'phone' ? 'email' : 'phone';
              });
              _resendOtp();
            },
            icon: Icon(
              _otpMethod == 'phone' ? Icons.email : Icons.phone,
              size: 20,
            ),
            label: Text(
              _otpMethod == 'phone'
                  ? 'Send via Email instead'
                  : 'Send via SMS instead',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showOtpStep = false;
                      _otpController.clear();
                      _otpError = null;
                      _otpMethod = 'phone';
                    });
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ActionButton(
                  text: 'Verify',
                  callback: _verifyOtpAndRegister,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
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

  Future<void> _register() async {
    if (_validateFields()) {
      setState(() {
        _nameError = null;
        _emailError = null;
        _passError = null;
        _confirmPassError = null;
        _phoneError = null;
        _isLoading = true;
      });
      
      final email = _emailController.text.trim();
      final password = _passController.text;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      
      try {
        debugPrint('Starting registration for: $email');
        
        // Check if user already exists
        final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
        if (existingUser != null) {
          setState(() {
            _isLoading = false;
            _emailError = 'An account already exists for that email';
          });
          return;
        }
        
        // Generate and send OTP
        await _sendOtp();
        
        // Show OTP verification step
        setState(() {
          _isLoading = false;
          _showOtpStep = true;
          _otpMethod = 'phone';
        });
      } catch (e) {
        debugPrint('Registration error: $e');
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  Future<void> _sendOtp() async {
    // Generate OTP
    final otp = OtpService.generateOtp();
    _generatedOtp = otp;
    
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    
    bool sent = false;
    
    // Send OTP based on selected method
    if (_otpMethod == 'phone' && phone.isNotEmpty) {
      sent = await OtpService.sendOtpViaSms(phone, otp);
    } else {
      sent = await OtpService.sendOtpViaEmail(email, otp);
    }
    
    if (mounted) {
      if (sent) {
        Fluttertoast.showToast(
          msg: 'Verification code sent to your ${_otpMethod == 'phone' ? 'phone' : 'email'}',
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        // Fallback: Show dialog if email/SMS couldn't be sent
        String recipient;
        if (_otpMethod == 'phone') {
          recipient = '+254$phone';
        } else {
          recipient = email;
        }
        
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          title: 'Could not send code automatically',
          desc: 'Please check your ${_otpMethod == 'phone' ? 'phone' : 'email'} for the verification code.\n\nVerification Code: $otp',
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
    await _sendOtp();
    Fluttertoast.showToast(
      msg: 'OTP resent successfully',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> _verifyOtpAndRegister() async {
    if (_validateOtp()) {
      setState(() {
        _otpError = null;
        _isLoading = true;
      });
      
      final email = _emailController.text.trim();
      final password = _passController.text;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      
      try {
        debugPrint('Verifying OTP and creating account for: $email');
        
        // Create user account in SQLite
        final userId = await DatabaseHelper.instance.createUser(
          email: email,
          password: password,
          name: name,
          phoneNumber: phone.isEmpty ? null : phone,
          bloodType: _bloodType,
          userRole: _userRole,
          isAdmin: false,
        );
        
        debugPrint('User created successfully with ID: $userId');
        
        // Save blood type to config
        final configBox = Hive.box(ConfigBox.key);
        configBox.put(ConfigBox.bloodType, _bloodType);
        
        // Set current user session
        await UserSession.setCurrentUserId(userId);
        
        if (mounted) {
          setState(() => _isLoading = false);
          Fluttertoast.showToast(
            msg: 'Account created successfully!',
          );
          
          debugPrint('Navigating to home screen');
          Navigator.of(context).pushNamedAndRemoveUntil(
            HomeScreen.route,
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Registration error: $e');
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
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

  bool _validateFields() {
    setState(() {
      _nameError = Validators.required(_nameController.text, 'Name');
      _emailError = Validators.required(_emailController.text, 'Email');
      _passError = Validators.required(_passController.text, 'Password');
      _confirmPassError = Validators.required(_confirmPassController.text, 'Confirm Password');
      _phoneError = Validators.required(_phoneController.text, 'Phone Number');
      
      // Check if passwords match
      if (_passError == null && _confirmPassError == null) {
        if (_passController.text != _confirmPassController.text) {
          _confirmPassError = 'Passwords do not match';
        }
      }
    });

    return _nameError == null && 
           _emailError == null && 
           _passError == null && 
           _confirmPassError == null && 
           _phoneError == null;
  }
}
