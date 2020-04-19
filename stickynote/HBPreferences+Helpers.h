#import <Cephei/HBPreferences.h>

@interface HBPreferences (Helpers)

- (NSInteger)nonZeroIntegerForKey:(NSString *)key fallback:(NSInteger)fallback;
- (BOOL)valueExistsForKey:(NSString *)key;

@end