//
//  WAEventEmitter.m
//  wise_apartment
//

#import "WAEventEmitter.h"

static void *kWAEventEmitterQueueKey = &kWAEventEmitterQueueKey;

@interface WAEventEmitter ()
@property (nonatomic, copy, nullable) FlutterEventSink flutterSink;   // <-- renamed (NO conflict)
@property (nonatomic, strong) dispatch_queue_t eventQueue;
@end

@implementation WAEventEmitter

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_queue_t q = dispatch_queue_create("com.wiseapartment.event_emitter", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(q, kWAEventEmitterQueueKey, kWAEventEmitterQueueKey, NULL);
        _eventQueue = q;

        NSLog(@"[WAEventEmitter] ✓ Event emitter initialized with queue");
    }
    return self;
}

#pragma mark - Queue helpers

- (dispatch_queue_t)ensureEventQueue {
    if (_eventQueue) return _eventQueue;

    dispatch_queue_t q = dispatch_queue_create("com.wiseapartment.event_emitter", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(q, kWAEventEmitterQueueKey, kWAEventEmitterQueueKey, NULL);
    _eventQueue = q;

    NSLog(@"[WAEventEmitter] ✓ eventQueue created lazily");
    return _eventQueue;
}

- (BOOL)isOnEventQueue {
    return dispatch_get_specific(kWAEventEmitterQueueKey) == kWAEventEmitterQueueKey;
}

#pragma mark - Public API (called by plugin)

/// IMPORTANT: This is your PUBLIC method used by WiseApartmentPlugin.
/// It MUST NOT conflict with any @property setter.
- (void)setEventSink:(FlutterEventSink)eventSink {
    NSLog(@"[WAEventEmitter] → setEventSink called (Flutter listening started)");

    dispatch_queue_t q = [self ensureEventQueue];

    // Avoid sync-deadlock if already on our queue
    if ([self isOnEventQueue]) {
        self.flutterSink = eventSink;
        NSLog(@"[WAEventEmitter] ✓ sink SET (direct)");
        return;
    }

    // Sync so that it becomes available immediately
    dispatch_sync(q, ^{
        self.flutterSink = eventSink;
        NSLog(@"[WAEventEmitter] ✓ sink SET (sync)");
    });
}

- (void)clearEventSink {
    NSLog(@"[WAEventEmitter] → clearEventSink called (Flutter stopped listening)");

    dispatch_queue_t q = [self ensureEventQueue];

    if ([self isOnEventQueue]) {
        self.flutterSink = nil;
        NSLog(@"[WAEventEmitter] ✓ sink CLEARED (direct)");
        return;
    }

    dispatch_async(q, ^{
        self.flutterSink = nil;
        NSLog(@"[WAEventEmitter] ✓ sink CLEARED (async)");
    });
}

- (void)emitEvent:(NSDictionary *)event {
    if (!event || ![event isKindOfClass:[NSDictionary class]]) {
        NSLog(@"[WAEventEmitter] ✗ ERROR: Invalid event format: %@", event);
        return;
    }

    NSString *eventType = event[@"type"];
    if (![eventType isKindOfClass:[NSString class]] || eventType.length == 0) {
        NSLog(@"[WAEventEmitter] ✗ ERROR: Event missing/invalid 'type': %@", event);
        return;
    }

    dispatch_queue_t q = [self ensureEventQueue];

    dispatch_async(q, ^{
        FlutterEventSink sink = self.flutterSink;
        if (!sink) {
            NSLog(@"[WAEventEmitter] ✗ WARNING: No active sink, DROPPING event: %@", eventType);
            return;
        }

        // Flutter sink must be called on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            sink(event);
            NSLog(@"[WAEventEmitter] ✓ Event '%@' dispatched to Flutter", eventType);
        });
    });
}

- (BOOL)hasActiveListener {
    dispatch_queue_t q = [self ensureEventQueue];

    if ([self isOnEventQueue]) {
        return (self.flutterSink != nil);
    }

    __block BOOL hasListener = NO;
    dispatch_sync(q, ^{
        hasListener = (self.flutterSink != nil);
    });

    return hasListener;
}

@end
