#import "NoteViewController.h"

@implementation NoteViewController

# pragma mark - Initialization

- (id)initWithNoteSize:(CGSize)size {
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		self.noteView = [[Note alloc] initWithFrame:CGRectMake(50, 50, size.width, size.height)];
		if (self.noteView) {
			[self.noteView setTextViewDelegate:self];
		}
	}
	return self;
}

# pragma mark - UITextView Delegate Methods

- (void)textViewDidBeginEditing:(UITextView *)textView {
	[self.noteView showDismissKeyboardButton];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	[self.noteView hideDismissKeyboardButton];
}

@end