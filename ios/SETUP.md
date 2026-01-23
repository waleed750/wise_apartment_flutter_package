# iOS Setup Instructions

## 1. Info.plist Required Keys

Add these entries to your app's `Info.plist` (located in `ios/Runner/Info.plist`):

```xml
<!-- Bluetooth Permission (iOS 13+) -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to discover and connect to your smart lock devices</string>

<!-- Bluetooth Peripheral Permission (if acting as peripheral) -->
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to communicate with smart lock devices</string>

<!-- Location Permission (required for BLE scanning on iOS 13+) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required for Bluetooth device scanning</string>

<!-- Optional: Location Always (if background scanning needed) -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Location access is required for Bluetooth device scanning in the background</string>

<!-- Background Modes (if needed for background BLE operations) -->
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <!-- Optional: Add bluetooth-peripheral if needed -->
</array>
```

## 2. Podfile Configuration

Make sure your `ios/Podfile` has the following minimum platform version:

```ruby
platform :ios, '12.0'
```

If your SDK framework is local (not on CocoaPods), add it to the Podfile:

```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # TODO: Add your SDK pod or local framework
  # Option 1: CocoaPods SDK
  # pod 'HXJBLESDK', '~> 2.5.0'
  
  # Option 2: Local framework
  # pod 'HXJBLESDK', :path => 'Frameworks/HXJBLESDK'
end
```

## 3. Framework Integration (if using vendored framework)

If you have a local SDK framework:

1. Create `ios/Frameworks/` directory
2. Copy `HXJBLESDK.framework` into it
3. Update `wise_apartment.podspec`:

```ruby
s.vendored_frameworks = 'Frameworks/HXJBLESDK.framework'
s.xcconfig = { 'OTHER_LDFLAGS' => '-framework HXJBLESDK' }
```

## 4. Install Dependencies

```bash
cd ios
pod install
cd ..
```

## 5. Build Settings (if needed)

Open `ios/Runner.xcworkspace` in Xcode and verify:

- **Deployment Target**: iOS 12.0 or higher
- **Build Settings → Framework Search Paths**: Include SDK framework location
- **Signing & Capabilities**: 
  - Enable "Background Modes" → "Uses Bluetooth LE accessories"
  - Ensure proper code signing

## 6. Privacy Permissions at Runtime

The plugin will automatically request Bluetooth permissions when needed. Ensure your app handles permission denial gracefully:

```dart
// In your Flutter app
try {
  await methodChannel.invokeMethod('startScan');
} on PlatformException catch (e) {
  if (e.code == '1003') {
    // Bluetooth is off - show user guidance
  } else if (e.code == '1004') {
    // Permission denied - guide user to Settings
  }
}
```

## 7. Common Issues & Solutions

### Issue: "Bluetooth permission denied"
**Solution**: Check Info.plist keys are present and app has requested permissions

### Issue: "Framework not found: HXJBLESDK"
**Solution**: 
- Verify framework is in correct location
- Run `pod install` again
- Clean build folder (Cmd+Shift+K in Xcode)

### Issue: "Scan not finding devices"
**Solution**: 
- Ensure Bluetooth is on
- Check location permissions (required for BLE scanning)
- Verify device is in pairing mode
- Check if service UUIDs filter is too restrictive

### Issue: "App crashes on launch"
**Solution**: 
- Verify all required frameworks are linked
- Check for missing Info.plist keys
- Review Xcode console for specific error

## 8. Testing Checklist

- [ ] Info.plist keys added
- [ ] Pods installed successfully
- [ ] App builds without errors
- [ ] Bluetooth permission prompt appears
- [ ] Scan returns devices (on physical device only)
- [ ] Event channel streams data
- [ ] Method channel calls succeed

## 9. Simulator Limitations

**What works in Simulator:**
- Channel communication
- Method calls (most)
- Error handling

**What DOES NOT work in Simulator:**
- BLE device scanning (no Bluetooth hardware)
- Device pairing
- WiFi configuration

**Always test on physical device for full functionality.**
