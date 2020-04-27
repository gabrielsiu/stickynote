#include "SNPColorPickerController.h"

@implementation SNPColorPickerController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"ColorPicker" target:self];
	}
	return _specifiers;
}

@end
