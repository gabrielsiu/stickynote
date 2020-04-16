@interface NSDictionary (DefaultsValue)

- (BOOL)boolValueForKey:(NSString *)key fallback:(BOOL)fallback;
- (NSInteger)intValueForKey:(NSString *)key fallback:(NSInteger)fallback;
- (double)doubleValueForKey:(NSString *)key fallback:(double)fallback;
- (UIColor *)colorValueForKey:(NSString *)key fallback:(NSString *)fallback;

@end