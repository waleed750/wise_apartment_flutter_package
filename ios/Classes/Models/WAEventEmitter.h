//
//  WAEventEmitter.h
//  wise_apartment
//
//  Thread-safe event emitter for streaming events to Flutter via EventChannel
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface WAEventEmitter : NSObject

/**
 * Set the Flutter event sink (called when Flutter starts listening)
 */
- (void)setEventSink:(FlutterEventSink)eventSink;

/**
 * Clear the event sink (called when Flutter stops listening or plugin is disposed)
 */
- (void)clearEventSink;

/**
 * Emit an event to Flutter (thread-safe, auto-dispatches to main queue)
 * @param event Dictionary containing event data (MUST include "type" key)
 */
- (void)emitEvent:(NSDictionary *)event;

/**
 * Check if there's an active listener
 */
- (BOOL)hasActiveListener;

@end

NS_ASSUME_NONNULL_END
