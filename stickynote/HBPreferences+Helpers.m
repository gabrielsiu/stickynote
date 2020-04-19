#import "HBPreferences+Helpers.h"

@implementation HBPreferences (Helpers)

// Only use this method if the value for the specified key should not be 0
- (NSInteger)nonZeroIntegerForKey:(NSString *)key fallback:(NSInteger)fallback {
	NSNumber *object = [self objectForKey:key];
	if (object) {
		return (object.intValue != 0) ? object.intValue : fallback;
	}
	return fallback;
}

// From my experience, omitting a value in a PSEditTextCell does not remove its entry from the prefs plist, but instead changes the corresponding value to an empty string
// Don't use this method for NSString values where an empty string is a valid value
- (BOOL)valueExistsForKey:(NSString *)key {
	if ([self objectForKey:key]) {
		NSString *value = [self objectForKey:key];
		return ![value isEqualToString:@""];
	}
	return NO;
}

@end