# OTP Configuration Guide

## Email Configuration (SMTP)

To enable email OTP sending, you need to configure SMTP settings in `lib/services/otp_service.dart`:

1. **For Gmail:**
   - Update `_smtpHost` to `'smtp.gmail.com'`
   - Update `_smtpPort` to `587`
   - Update `_smtpUsername` to your Gmail address
   - Update `_smtpPassword` to your Gmail App Password (not your regular password)
   - Update `_senderEmail` to your Gmail address
   
   **How to get Gmail App Password:**
   1. Go to your Google Account settings
   2. Enable 2-Step Verification
   3. Go to App Passwords
   4. Generate a new app password for "Mail"
   5. Use this 16-character password in `_smtpPassword`

2. **For Other Email Providers:**
   - Update SMTP host, port, and credentials accordingly
   - Common SMTP settings:
     - Outlook: `smtp-mail.outlook.com`, port `587`
     - Yahoo: `smtp.mail.yahoo.com`, port `587`
     - Custom: Check with your email provider

## SMS Configuration

SMS sending works automatically on Android devices with SMS permissions. The app will request SMS permissions when needed.

**Note:** SMS sending may incur charges depending on your mobile carrier plan.

## Testing

If SMTP is not configured, the app will fall back to showing the OTP in a dialog for testing purposes.

