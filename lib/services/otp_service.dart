import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OtpService {
  static String? _lastGeneratedOtp;
  static DateTime? _lastOtpTime;
  
  // SMTP Configuration - Update these with your email service credentials
  // For Gmail, you'll need to use an App Password
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = 'your-email@gmail.com'; // Update this
  static const String _smtpPassword = 'your-app-password'; // Update this - use App Password for Gmail
  static const String _senderEmail = 'your-email@gmail.com'; // Update this
  static const String _senderName = 'Blood Donation App';

  /// Generate a 6-digit OTP
  static String generateOtp() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    _lastGeneratedOtp = otp;
    _lastOtpTime = DateTime.now();
    debugPrint('Generated OTP: $otp');
    return otp;
  }

  /// Verify OTP
  static bool verifyOtp(String inputOtp) {
    if (_lastGeneratedOtp == null) {
      return false;
    }
    return inputOtp == _lastGeneratedOtp;
  }

  /// Send OTP via Email using SMTP
  /// This sends the email directly without opening the email app
  static Future<bool> sendOtpViaEmail(String email, String otp) async {
    try {
      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: true,
      );

      // Create the email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(email)
        ..subject = 'Blood Donation App - Verification Code'
        ..html = '''
          <html>
            <body>
              <h2>Verification Code</h2>
              <p>Your verification code is:</p>
              <h1 style="color: #d32f2f; font-size: 32px; letter-spacing: 5px;">$otp</h1>
              <p>This code will expire in 10 minutes.</p>
              <p>If you did not request this code, please ignore this email.</p>
            </body>
          </html>
        '''
        ..text = '''
          Verification Code: $otp
          
          This code will expire in 10 minutes.
          
          If you did not request this code, please ignore this email.
        ''';

      // Send the email
      await send(message, smtpServer);
      debugPrint('OTP email sent successfully to: $email');
      return true;
    } catch (e) {
      debugPrint('Error sending OTP via email: $e');
      // If SMTP fails, fall back to showing OTP (for development/testing)
      if (kDebugMode) {
        debugPrint('SMTP configuration may be missing. Please configure SMTP settings in OtpService.');
      }
      return false;
    }
  }

  /// Send OTP via SMS directly using platform channels
  /// This sends the SMS directly without opening the SMS app
  static Future<bool> sendOtpViaSms(String phoneNumber, String otp) async {
    try {
      // Request SMS permission
      final status = await Permission.sms.request();
      if (!status.isGranted) {
        debugPrint('SMS permission not granted');
        return false;
      }
      
      // Format phone number
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+254${formattedPhone.substring(1)}';
        } else {
          formattedPhone = '+254$formattedPhone';
        }
      }
      
      final message = 'Your Blood Donation App verification code is: $otp\n\n'
          'This code will expire in 10 minutes.\n\n'
          'If you did not request this code, please ignore this message.';
      
      // Use platform channel to send SMS
      const platform = MethodChannel('com.example.blood_donation/sms');
      try {
        await platform.invokeMethod('sendSms', {
          'phoneNumber': formattedPhone,
          'message': message,
        });
        debugPrint('OTP SMS sent successfully to: $formattedPhone');
        return true;
      } on PlatformException catch (e) {
        debugPrint('Failed to send SMS: ${e.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending OTP via SMS: $e');
      return false;
    }
  }

  /// Send OTP - tries email first, then SMS as fallback
  static Future<bool> sendOtp(String email, String? phoneNumber, String otp) async {
    // Try email first
    final emailSent = await sendOtpViaEmail(email, otp);
    if (emailSent) {
      return true;
    }
    
    // If email fails and phone number is available, try SMS
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      return await sendOtpViaSms(phoneNumber, otp);
    }
    
    return false;
  }

  /// Check if OTP is still valid (10 minutes expiry)
  static bool isOtpValid() {
    if (_lastOtpTime == null) {
      return false;
    }
    final now = DateTime.now();
    final difference = now.difference(_lastOtpTime!);
    return difference.inMinutes < 10;
  }

  /// Clear stored OTP
  static void clearOtp() {
    _lastGeneratedOtp = null;
    _lastOtpTime = null;
  }
}

