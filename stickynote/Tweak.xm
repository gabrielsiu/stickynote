#import "Constants.h"
#import "NSDictionary+DefaultsValue.h"
#import "Note.h"

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

Note *noteView;
UIButton *hideButton;
NSDictionary *defaults;
CGPoint initialCenter;

# pragma mark - CSCoverSheetViewBase Hook

%hook CSCoverSheetViewBase

- (void)didMoveToSuperview {
	%orig;
	if (!noteView) {
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
	NSInteger width = [defaults intValueForKey:@"width" fallback:kDefaultNoteSize];
	NSInteger height = [defaults intValueForKey:@"height" fallback:kDefaultNoteSize];
	noteView = [[Note alloc] initWithFrame:CGRectMake(50, 50, width, height) defaults:defaults];

	UIPanGestureRecognizer *fingerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
	[noteView addGestureRecognizer:fingerDrag];

	[self addSubview:noteView];
}

%new
- (void)setupHideButton {
	if (!noteView) { return; }
	hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[hideButton setImage:[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-note.png"]] forState:UIControlStateNormal];

	NSNumber *defaultsXOffset = [defaults valueForKey:@"xOffset"];
	NSNumber *defaultsYOffset = [defaults valueForKey:@"yOffset"];
	NSInteger xOffset = defaultsXOffset ? defaultsXOffset.intValue : 0;
	NSInteger yOffset = defaultsYOffset ? defaultsYOffset.intValue : 0;
	hideButton.frame = CGRectMake(xOffset, self.frame.size.height - 1.2*kIconSize - yOffset, 1.2*kIconSize, 1.2*kIconSize);

	[hideButton addTarget:self action:@selector(didPressHideButton:) forControlEvents:UIControlEventTouchUpInside];
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[hideButton addGestureRecognizer:longPress];

	[self addSubview:hideButton];
}


#pragma mark Actions

%new
- (void)didPressHideButton:(UIButton *)sender {
	BOOL shouldHide = !noteView.isHidden;
	double alphaValue;
	if ([defaults boolValueForKey:@"useCustomAlpha" fallback:NO]) {
		alphaValue = [defaults doubleValueForKey:@"alphaValue" fallback:kDefaultAlpha];
	} else {
		alphaValue = kDefaultAlpha;
	}
	CGFloat finalAlpha = shouldHide ? 0.0f : alphaValue;

	NSTimeInterval duration;
	if ([defaults boolValueForKey:@"useCustomDuration" fallback:NO]) {
		duration = [defaults doubleValueForKey:@"customDuration" fallback:kDefaultAnimDuration];
	} else {
		duration = kDefaultAnimDuration;
	}

	if (!shouldHide) { [noteView setHidden:NO]; }
	[UIView animateWithDuration:duration animations:^{
		[noteView setAlpha:finalAlpha];
	} completion:^(BOOL finished) {
		if (shouldHide) { [noteView setHidden:YES]; }
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

// Handle long press gesture for returning note to center of screen
%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateBegan) {
		[UIView animateWithDuration:0.3f animations:^{
			noteView.center = CGPointMake(noteView.superview.frame.size.width / 2, noteView.superview.frame.size.height / 2);
		} completion:NULL];
	}
}

%end