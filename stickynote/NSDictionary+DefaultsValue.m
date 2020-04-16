#import "NSDictionary+DefaultsValue.h"

@implementation NSDictionary (DefaultsValue)

- (BOOL)boolValueForKey:(NSString *)key fallback:(BOOL)fallback {
	id defaultsValue = [self valueForKey:key];
	if (defaultsValue) {
		return [defaultsValue isEqual:@1];
	} else {
		return fallback;
	}
}

// Only use this method if the value for the specified key should not be 0
- (NSInteger)intValueForKey:(NSString *)key fallback:(NSInteger)fallback {
	NSNumber *defaultsValue = [self valueForKey:key];
	if (defaultsValue) {
		if (defaultsValue.intValue != 0) {
			return defaultsValue.intValue;
		} else {
			return fallback;
		}
	}
	return fallback;
}

- (double)doubleValueForKey:(NSString *)key fallback:(double)fallback {
	NSNumber *defaultsValue = [self valueForKey:key];
	return defaultsValue ? defaultsValue.doubleValue : fallback;
}

- (UIColor *)colorValueForKey:(NSString *)key fallback:(NSString *)fallback {
	return [UIColor yellowColor];
	// TODO: Fix colors
	// NSString *colorHexString = [self objectForKey:key];
	// if (colorHexString) {
	// 	return LCPParseColorString(colorHexString, fallback);
	// }
	// return LCPParseColorString(fallback, fallback);
}

@end
