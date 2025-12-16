# Firebase Setup Guide for Blood Donation App

This guide will help you set up Firebase Authentication for your Blood Donation app.

## Prerequisites

1. A Google account
2. Flutter development environment set up
3. Android Studio or VS Code with Flutter extensions

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Enter project name (e.g., "Blood Donation App")
4. Follow the setup wizard (disable Google Analytics if you don't need it)
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In Firebase Console, click the Android icon (or "Add app" > Android)
2. Enter your Android package name:
   - Check `android/app/build.gradle` for `applicationId`
   - Usually something like `com.example.blood_donation`
3. Enter app nickname (optional)
4. Enter debug signing certificate SHA-1 (optional for development)
5. Click "Register app"

## Step 3: Download Configuration File

1. Download `google-services.json`
2. Place it in `android/app/` directory
3. **Important**: Make sure the file is named exactly `google-services.json`

## Step 4: Update Android Build Files

### Update `android/build.gradle`:

Add to the `buildscript` dependencies:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### Update `android/app/build.gradle`:

Add at the bottom of the file:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 5: Enable Firebase Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Enable "Email/Password" authentication:
   - Click "Email/Password"
   - Toggle "Enable"
   - Click "Save"

## Step 6: Install Dependencies

Run in your project root:
```bash
flutter pub get
```

## Step 7: Test the Setup

1. Run the app: `flutter run`
2. Try registering a new user
3. Check Firebase Console > Authentication to see if the user appears

## Troubleshooting

### Error: "Default FirebaseApp is not initialized"
- Make sure `google-services.json` is in `android/app/`
- Make sure you've added the Google Services plugin to `build.gradle`
- Run `flutter clean` and `flutter pub get`

### Error: "PlatformException"
- Make sure Firebase Authentication is enabled in Firebase Console
- Check that your package name matches in Firebase Console and `build.gradle`

### Users not appearing in Firebase Console
- Check that you're using Firebase Auth methods (not local SQLite auth)
- Verify the app is connected to the internet

## Notes

- **Development**: The app will continue to work even if Firebase isn't set up (for backward compatibility)
- **Production**: Make sure Firebase is properly configured before releasing
- **Data**: User authentication is handled by Firebase, but all other data (requests, offers, messages) remains in local SQLite

## Next Steps

After setup, users will be able to:
- Register and login from any device
- Access their account across multiple devices
- Reset passwords via Firebase

All other app data (blood requests, donation offers, messages) remains stored locally in SQLite on each device.

