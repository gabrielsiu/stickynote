#import "Constants.h"
#import "NSDictionary+DefaultsValue.h"
#import "NoteViewController.h"

@implementation NoteViewController

# pragma mark - Initialization

- (id)initWithDefaults:(NSDictionary *)defaultsDict {
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		NSInteger width = [defaultsDict defaultsValueForKey:@"width" fallback:kDefaultNoteSize];
		NSInteger height = [defaultsDict defaultsValueForKey:@"height" fallback:kDefaultNoteSize];

		self.noteView = [[Note alloc] initWithFrame:CGRectMake(50, 50, width, height) defaults:defaultsDict];
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