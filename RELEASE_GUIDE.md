# 🚀 EduLearn App Release Guide

## **Step 1: Generate Signing Key**
```bash
cd C:\Users\NICE\Documents\App\EduLearn
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## **Step 2: Update key.properties**
Edit `android/key.properties` with your actual passwords:
```
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

## **Step 3: Build Release APK**
```bash
# Clean project
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## **Step 4: Locate Release Files**
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **AAB**: `build/app/outputs/bundle/release/app-release.aab`

## **Step 5: Test Release Build**
```bash
# Install APK on device
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer APK to phone and install manually
```

## **Step 6: Play Store Upload (Optional)**
1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app
3. Upload `app-release.aab` file
4. Fill app details, screenshots, descriptions
5. Submit for review

## **Quick Commands**
```bash
# Full release build
flutter clean && flutter pub get && flutter build apk --release

# Check APK size
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Install on connected device
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## **Release Checklist**
- ✅ App signing configured
- ✅ Release APK builds successfully  
- ✅ APK installs and runs on device
- ✅ All features work (assignments, biometric, etc.)
- ✅ No debug code or console logs
- ✅ App icon and name correct
- ✅ Permissions properly configured

Your EduLearn app is ready for release! 🎉