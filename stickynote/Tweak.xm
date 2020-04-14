#import "Constants.h"
#import "NoteViewController.h"

# pragma mark - Interfaces

@interface SBFTouchPassThroughView : UIView
@end

@interface CSCoverSheetViewBase : SBFTouchPassThroughView

- (void)didMoveToSuperview;

- (void)setupNote;
- (void)setupHideButton;
- (void)didPressHideButton:(UIButton *)sender;
- (void)handleDrag:(UIPanGestureRecognizer *)sender;

@end

NoteViewController *noteVC;
UIButton *hideButton;
CGPoint initialCenter;

# pragma mark - CSCoverSheetViewBase Hook

%hook CSCoverSheetViewBase

- (void)didMoveToSuperview {
	%orig;
	if (!noteVC) {
		if ([self.superview isMemberOfClass:[%c(CSMainPageView) class]]) {
			[self setupNote];
			[self setupHideButton];
		}
	}
}

# pragma mark Setup

%new
- (void)setupNote {
	CGSize noteSize = CGSizeMake(250, 250);
	noteVC = [[NoteViewController alloc] initWithNoteSize:noteSize];

	UIPanGestureRecognizer *fingerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
	[noteVC.noteView addGestureRecognizer:fingerDrag];

	[self addSubview:noteVC.noteView];
}

%new
- (void)setupHideButton {
	if (!noteVC.noteView) { return; }
	hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[hideButton setImage:[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-note-light.png"]] forState:UIControlStateNormal];
	hideButton.frame = CGRectMake(0, self.frame.size.height - kIconSize - 15, kIconSize + 15, kIconSize + 15);
	[hideButton addTarget:self action:@selector(didPressHideButton:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:hideButton];
}


#pragma mark Actions

%new
- (void)didPressHideButton:(UIButton *)sender {
	BOOL shouldHide = !noteVC.noteView.isHidden;
	CGFloat finalAlpha = shouldHide ? 0.0f : 0.8f;

	if (!shouldHide) { [noteVC.noteView setHidden:NO]; }
	[UIView animateWithDuration:0.2f animations:^{
		[noteVC.noteView setAlpha:finalAlpha];
	} completion:^(BOOL finished) {
		if (shouldHide) { [noteVC.noteView setHidden:YES]; }
	}];
}

// Handle pan gesture for dragging the note around
// Adapted from https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_uikit_gestures/handling_pan_gestures
%new
- (void)handleDrag:(UIPanGestureRecognizer *)sender {
	if (!sender.view) { return; }
	
	UIView *noteView = sender.view;
	CGPoint translation = [sender translationInView:noteView.superview];
	
	if (sender.state == UIGestureRecognizerStateBegan) {
		initialCenter = noteView.center;
	}
	if (sender.state != UIGestureRecognizerStateCancelled) {
		noteView.center = CGPointMake(initialCenter.x + translation.x, initialCenter.y + translation.y);
	} else {
		noteView.center = initialCenter;
	}
}

%end