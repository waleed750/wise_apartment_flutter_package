#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wise_apartment.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'wise_apartment'
  s.version          = '0.0.1'
  s.summary          = 'iOS plugin for Smart Lock SDK integration'
  s.description      = <<-DESC
Flutter plugin providing BLE device scanning, pairing, and WiFi configuration for Smart Lock devices.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  # TODO: Add your SDK framework dependency
  # Option 1: If SDK is available via CocoaPods
  # s.dependency 'HXJBLESDK', '~> 2.5.0'
  
  # Option 2: If SDK is a vendored framework (local)
  # s.vendored_frameworks = 'Frameworks/HXJBLESDK.framework'
  # s.xcconfig = { 'OTHER_LDFLAGS' => '-framework HXJBLESDK' }
  
  # Option 3: If SDK requires additional system frameworks
  s.frameworks = 'CoreBluetooth', 'Foundation'
  
  s.swift_version = '5.0'
end
