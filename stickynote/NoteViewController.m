#import "Constants.h"
#import "HBPreferences+Helpers.h"
#import "NoteViewController.h"

@implementation NoteViewController

# pragma mark - Initialization

- (id)initWithPrefs:(HBPreferences *)preferences screenSize:(CGSize)size locked:(BOOL)locked {
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		NSInteger width = [preferences nonZeroIntegerForKey:@"width" fallback:kDefaultNoteSize];
		NSInteger height = [preferences nonZeroIntegerForKey:@"height" fallback:kDefaultNoteSize];
		CGFloat noteX = (size.width - width) / 2.0f;
		CGFloat noteY = (size.height - height) / 2.0f;

		self.noteView = [[Note alloc] initWithFrame:CGRectMake(noteX, noteY, width, height) prefs:preferences locked:locked];
		if (self.noteView) {
			[self.noteView setTextViewDelegate:self];
		}
	}
	return self;
}

# pragma mark - UITextView Delegate Methods

- (void)textViewDidEndEditing:(UITextView *)textView {
	[self.noteView saveText];
}

@end