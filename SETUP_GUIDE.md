# 🚀 EduLearn App Setup Guide

## Prerequisites
1. **Flutter SDK** - [Install Flutter](https://flutter.dev/docs/get-started/install)
2. **Android Studio** - [Download](https://developer.android.com/studio)
3. **Git** - [Install Git](https://git-scm.com/)

## Setup Steps

### 1. Clone Repository
```bash
git clone [YOUR_REPO_URL]
cd EduLearn
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Setup Android
```bash
# Check if everything is setup correctly
flutter doctor

# Connect device or start emulator
flutter devices
```

### 4. Run the App
```bash
# Debug mode
flutter run

# Release APK
flutter build apk --release
```

## Firebase Setup (If Issues)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project or use existing
3. Add Android app with package: `com.example.e_education`
4. Download `google-services.json` → place in `android/app/`
5. Enable Authentication & Firestore

## Troubleshooting
- Run `flutter clean` then `flutter pub get`
- Check `flutter doctor` for missing dependencies
- Ensure Android SDK is installed
- Enable USB debugging on phone

## App Features
- ✅ Assignment submission
- ✅ Biometric authentication
- ✅ 8 sample assignments
- ✅ Search & filter functionality