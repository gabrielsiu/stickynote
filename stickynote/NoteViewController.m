#import "Constants.h"
#import "HBPreferences+Helpers.h"
#import "NoteViewController.h"

@implementation NoteViewController

#pragma mark - Initialization

- (id)initWithPrefs:(HBPreferences *)preferences screenSize:(CGSize)size {
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		NSInteger width = [preferences nonZeroIntegerForKey:@"width" fallback:kDefaultNoteSize];
		NSInteger height = [preferences nonZeroIntegerForKey:@"height" fallback:kDefaultNoteSize];
		
		NSString *savedPosition = [[NSUserDefaults standardUserDefaults] objectForKey:@"stickynote_position"];
		CGPoint position;
		if (savedPosition) {
			// Restore note to previous position
			position = CGPointFromString(savedPosition);
		} else {
			// Initialize note in the center of the screen if no position was saved
			position = CGPointMake((size.width - width) / 2.0f, (size.height - height) / 2.0f);
		}

		self.noteView = [[Note alloc] initWithFrame:CGRectMake(position.x, position.y, width, height) prefs:preferences];
		if (self.noteView) {
			[self.noteView setTextViewDelegate:self];

			// Restore hidden status of note
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"stickynote_hidden"] ?: NO) {
				[self.noteView setHidden:YES];
			}
		}
	}
	return self;
}

#pragma mark - UITextView Delegate Methods

- (void)textViewDidEndEditing:(UITextView *)textView {
	[self.noteView saveText];
}

@end