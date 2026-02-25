#import "PluginUtils.h"

@implementation PluginUtils

+ (NSString *)stringArg:(NSDictionary *)args key:(NSString *)key {
    id v = args[key];
    if ([v isKindOfClass:[NSString class]]) return (NSString *)v;
    if ([v isKindOfClass:[NSNumber class]]) return [(NSNumber *)v stringValue];
    return nil;
}

+ (NSNumber *)numberArg:(NSDictionary *)args key:(NSString *)key {
    id v = args[key];
    if ([v isKindOfClass:[NSNumber class]]) return (NSNumber *)v;
    if ([v isKindOfClass:[NSString class]]) {
        NSInteger n = [(NSString *)v integerValue];
        return @(n);
    }
    return nil;
}

+ (NSString *)lockMacFromArgs:(NSDictionary *)args {
    NSString *mac = [self stringArg:args key:@"mac"];

    // If not present at top-level, look inside `dna` map (common on iOS calls)
    if (!mac || mac.length == 0) {
        id dna = args[@"dna"];
        if ([dna isKindOfClass:[NSDictionary class]]) {
            mac = [self stringArg:(NSDictionary *)dna key:@"mac"];
        }
    }

    // Also support `wifi` payloads which may contain lockMac or mac
    if (!mac || mac.length == 0) {
        id wifi = args[@"wifi"];
        if ([wifi isKindOfClass:[NSDictionary class]]) {
            mac = [self stringArg:(NSDictionary *)wifi key:@"lockMac"] ?: [self stringArg:(NSDictionary *)wifi key:@"mac"];
        } else if ([wifi isKindOfClass:[NSString class]]) {
            NSData *d = [(NSString *)wifi dataUsingEncoding:NSUTF8StringEncoding];
            if (d) {
                NSError *err = nil;
                id obj = [NSJSONSerialization JSONObjectWithData:d options:0 error:&err];
                if (!err && [obj isKindOfClass:[NSDictionary class]]) {
                    mac = [self stringArg:(NSDictionary *)obj key:@"lockMac"] ?: [self stringArg:(NSDictionary *)obj key:@"mac"];
                }
            }
        }
    }

    if (mac.length == 0) return nil;
    return [mac lowercaseString];
}

+ (int)intFromArgs:(NSDictionary *)args key:(NSString *)key defaultValue:(int)defaultValue {
    NSNumber *n = [self numberArg:args key:key];
    if (!n) return defaultValue;
    return (int)[n integerValue];
}

@end
