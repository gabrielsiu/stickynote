#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface HBListController : PSListController

- (BOOL)containsSpecifier:(id)arg1;

@end

@interface SNPRootListController : HBListController

@property (nonatomic, retain) NSMutableDictionary *savedSpecifiers;

@end