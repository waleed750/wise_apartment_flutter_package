//
//  WiseApartmentPlugin.h
//  wise_apartment
//
//  Flutter plugin bridge for Smart Lock SDK (iOS)
//  Exposes BLE scanning, pairing, WiFi config via MethodChannel + EventChannel
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface WiseApartmentPlugin : NSObject<FlutterPlugin, FlutterStreamHandler>

@end

NS_ASSUME_NONNULL_END
