# Testing on Phone - Guide

## Prerequisites

### For Android:
1. **Enable Developer Options** on your Android phone:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - You'll see "You are now a developer!"

2. **Enable USB Debugging**:
   - Go to Settings → Developer Options
   - Enable "USB Debugging"
   - Enable "Install via USB" (if available)

3. **Connect Phone via USB**:
   - Connect your phone to your computer with a USB cable
   - On your phone, allow USB debugging when prompted

### For iOS:
1. **Install Xcode** (if not already installed):
   ```bash
   # Check if Xcode is installed
   xcode-select --version
   
   # If not, install from App Store or:
   xcode-select --install
   ```

2. **Install CocoaPods**:
   ```bash
   sudo gem install cocoapods
   ```

3. **Connect iPhone via USB**:
   - Connect your iPhone to your Mac
   - Trust the computer on your iPhone when prompted

4. **Configure Signing** (for iOS):
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select your development team in Signing & Capabilities

## Step-by-Step Testing

### Step 1: Check Available Devices

Run this command to see connected devices:

```bash
flutter devices
```

You should see your phone listed, for example:
```
iPhone 15 Pro (mobile) • 12345678-ABCD-EFGH-IJKL-MNOPQRSTUVWX • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-0
Chrome (web) • chrome • web-javascript • Google Chrome 120.0.6099.109
```

### Step 2: Run on Android Phone

```bash
# List devices
flutter devices

# Run on Android (replace 'device-id' with your device ID)
flutter run -d <device-id>

# Or if only one device is connected:
flutter run
```

**If you see "No devices found":**
- Make sure USB debugging is enabled
- Try a different USB cable
- Check if drivers are installed (Windows)
- Run `adb devices` to check Android Debug Bridge

### Step 3: Run on iPhone

```bash
# List devices
flutter devices

# Run on iPhone
flutter run -d <device-id>

# Or if only one device is connected:
flutter run
```

**If you see signing errors:**
- Open `ios/Runner.xcworkspace` in Xcode
- Select your development team
- Make sure you have a valid Apple Developer account (free account works for testing)

### Step 4: Wireless Debugging (Optional)

#### Android (Wireless):
1. Connect phone via USB first
2. Run: `adb tcpip 5555`
3. Disconnect USB
4. Connect to same WiFi as computer
5. Find phone's IP address (Settings → About Phone → IP Address)
6. Run: `adb connect <phone-ip>:5555`
7. Now you can run `flutter run` wirelessly

#### iOS (Wireless):
1. Connect iPhone via USB
2. In Xcode: Window → Devices and Simulators
3. Select your device
4. Check "Connect via network"
5. Disconnect USB
6. Run `flutter run` - it should connect wirelessly

## Quick Commands

```bash
# See all connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run in release mode (faster, no debug features)
flutter run --release

# Run with hot reload enabled (default)
flutter run

# Build APK for Android (without running)
flutter build apk

# Build IPA for iOS (requires Xcode)
flutter build ios
```

## Troubleshooting

### Android Issues:

**"No devices found"**
```bash
# Check ADB connection
adb devices

# If device shows as "unauthorized":
# - Check phone for USB debugging authorization prompt
# - Revoke USB debugging authorizations on phone and reconnect

# Restart ADB server
adb kill-server
adb start-server
```

**"Waiting for connection from debug service"**
- Make sure phone and computer are on same network
- Check firewall settings
- Try USB connection instead

### iOS Issues:

**"No signing certificate found"**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Signing & Capabilities
3. Select your Team
4. Xcode will automatically create certificates

**"Device not trusted"**
- On iPhone: Settings → General → VPN & Device Management
- Trust your developer certificate

**"Could not find Developer Disk Image"**
- Update Xcode to latest version
- Update iOS on your phone to match Xcode version

### General Issues:

**"Flutter not found"**
- Make sure Flutter is in your PATH
- Run `flutter doctor` to check setup

**Build errors**
- Run `flutter clean`
- Run `flutter pub get`
- Try again

## Testing Features

Once the app is running on your phone:

1. **Test Navigation**:
   - Use bottom navigation bar
   - Switch between tabs

2. **Test Coach Features**:
   - Create a workout
   - Add exercises
   - View workout list
   - Delete workouts

3. **Test Client Features**:
   - View assigned workouts
   - Mark workouts complete
   - Log water intake
   - Track daily progress

4. **Test on Different Screens**:
   - Rotate device (if supported)
   - Test on different screen sizes

## Hot Reload & Hot Restart

While the app is running:

- Press `r` in terminal → Hot reload (fast, keeps state)
- Press `R` in terminal → Hot restart (slower, resets state)
- Press `q` → Quit

## Building for Distribution

### Android APK:
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# APK will be in: build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA:
```bash
# Build for iOS (requires Xcode)
flutter build ios --release

# Then open Xcode and archive/export
```

---

**Quick Start**: Connect your phone, run `flutter devices`, then `flutter run`! 🚀

