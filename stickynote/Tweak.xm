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
NSDictionary *defaults;
CGPoint initialCenter;

# pragma mark - CSCoverSheetViewBase Hook

%hook CSCoverSheetViewBase

- (void)didMoveToSuperview {
	%orig;
	if (!noteVC) {
		if ([self.superview isMemberOfClass:[%c(CSMainPageView) class]]) {
			defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.gabrielsiu.stickynoteprefs"];
			[self setupNote];
			[self setupHideButton];
		}
	}
}

# pragma mark Setup

%new
- (void)setupNote {
	noteVC = [[NoteViewController alloc] initWithDefaults:defaults];

	UIPanGestureRecognizer *fingerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
	[noteVC.noteView addGestureRecognizer:fingerDrag];

	[self addSubview:noteVC.noteView];
}

%new
- (void)setupHideButton {
	if (!noteVC.noteView) { return; }
	hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[hideButton setImage:[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-note-light.png"]] forState:UIControlStateNormal];
	hideButton.backgroundColor = [UIColor redColor];

	NSNumber *defaultsXOffset = [defaults valueForKey:@"xOffset"];
	NSNumber *defaultsYOffset = [defaults valueForKey:@"yOffset"];
	NSInteger xOffset = defaultsXOffset ? defaultsXOffset.intValue : 0;
	NSInteger yOffset = defaultsYOffset ? defaultsYOffset.intValue : 0;
	hideButton.frame = CGRectMake(xOffset, self.frame.size.height - kIconSize - 15 - yOffset, kIconSize + 15, kIconSize + 15);
	[hideButton addTarget:self action:@selector(didPressHideButton:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:hideButton];
}


#pragma mark Actions

%new
- (void)didPressHideButton:(UIButton *)sender {
	BOOL shouldHide = !noteVC.noteView.isHidden;
	CGFloat finalAlpha = shouldHide ? 0.0f : 0.8f;

	NSTimeInterval duration;
	id useCustomDuration = [defaults valueForKey:@"useCustomDuration"];
	if (useCustomDuration) {
		if ([useCustomDuration isEqual:@1]) {
			NSNumber *defaultsDuration = [defaults valueForKey:@"customDuration"];
			if (defaultsDuration) {
				duration = defaultsDuration.doubleValue;
			} else {
				duration = kDefaultAnimDuration;
			}
		} else {
			duration = kDefaultAnimDuration;
		}
	} else {
		duration = kDefaultAnimDuration;
	}
	
	if (!shouldHide) { [noteVC.noteView setHidden:NO]; }
	[UIView animateWithDuration:duration animations:^{
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