#import "NSDictionary+DefaultsValue.h"

@implementation NSDictionary (DefaultsValue)

// Only use if the value for the specified key should not be 0
- (NSInteger)defaultsValueForKey:(NSString *)key fallback:(NSInteger)fallback {
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

@end
