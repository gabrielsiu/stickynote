#include "SNPAcknowledgementsController.h"

@implementation SNPAcknowledgementsController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Acknowledgements" target:self];
	}

	return _specifiers;
}

@end
