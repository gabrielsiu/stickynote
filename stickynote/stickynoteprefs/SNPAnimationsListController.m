#include "SNPAnimationsListController.h"

@implementation SNPAnimationsListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"AnimationsList" target:self];
	}
	return _specifiers;
}

@end
