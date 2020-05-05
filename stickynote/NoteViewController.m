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
			self.noteView.delegate = self;

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

#pragma mark - ButtonActionDelegate Methods

- (void)didPressShareButton:(Note *)sender {
	
	NSArray *items = @[[self.noteView getText]];
	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
	
	// Make the presentation a popover for iPads
	controller.modalPresentationStyle = UIModalPresentationPopover;
	UIPopoverPresentationController *popController = [controller popoverPresentationController];
	popController.barButtonItem = self.noteView.shareButtonItem;
	[self presentViewController:controller animated:YES completion:nil];

	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *error) {
		if (error) {
			NSString *errorMessage = [NSString stringWithFormat: @"%@, %@", error.localizedDescription, error.localizedFailureReason];
			UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Error sharing Note" message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
			[alertController addAction:okAction];
			[self presentViewController:alertController animated:YES completion:nil];
		}
	};
}

- (void)didPressClearButton:(Note *)sender {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Clear Note" message:@"The contents of the note will be cleared. This action cannot be undone." preferredStyle:UIAlertControllerStyleActionSheet];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction* clearAction = [UIAlertAction actionWithTitle:@"Clear Note" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
		[self.noteView clearTextView];
	}];
	[alertController addAction:cancelAction];
	[alertController addAction:clearAction];

	// Make the presentation a popover for iPads
	alertController.modalPresentationStyle = UIModalPresentationPopover;
	UIPopoverPresentationController *popController = [alertController popoverPresentationController];
	popController.barButtonItem = self.noteView.clearButtonItem;
	[self presentViewController:alertController animated:YES completion:nil];
}

@end