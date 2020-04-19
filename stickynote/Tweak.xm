#import <Cephei/HBPreferences.h>
#import "HBPreferences+Helpers.h"
#import "Constants.h"
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

HBPreferences *prefs;
Note *noteView;
UIButton *hideButton;
CGPoint initialCenter;

# pragma mark - Tweak

%group Tweak

%hook CSCoverSheetViewBase

- (void)didMoveToSuperview {
	%orig;
	if (!noteView) {
		if ([self.superview isMemberOfClass:[%c(CSMainPageView) class]]) {
			[self setupNote];
			[self setupHideButton];
		}
	}
}

# pragma mark Setup

%new
- (void)setupNote {
	NSInteger width = [prefs nonZeroIntegerForKey:@"width" fallback:kDefaultNoteSize];
	NSInteger height = [prefs nonZeroIntegerForKey:@"height" fallback:kDefaultNoteSize];
	noteView = [[Note alloc] initWithFrame:CGRectMake(50, 50, width, height) prefs:prefs];

	UIPanGestureRecognizer *fingerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
	[noteView addGestureRecognizer:fingerDrag];

	[self addSubview:noteView];
}

%new
- (void)setupHideButton {
	if (!noteView) { return; }
	hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[hideButton setImage:[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-note.png"]] forState:UIControlStateNormal];

	NSInteger xOffset = [([prefs objectForKey:@"xOffset"] ?: @0) intValue];
	NSInteger yOffset = [([prefs objectForKey:@"yOffset"] ?: @0) intValue];
	hideButton.frame = CGRectMake(xOffset, self.frame.size.height - 1.2*kIconSize - yOffset, 1.2*kIconSize, 1.2*kIconSize);

	[hideButton addTarget:self action:@selector(didPressHideButton:) forControlEvents:UIControlEventTouchUpInside];
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[hideButton addGestureRecognizer:longPress];

	[self addSubview:hideButton];
}


# pragma mark Actions

%new
- (void)didPressHideButton:(UIButton *)sender {
	BOOL shouldHide = !noteView.isHidden;
	double alphaValue;
	if ([([prefs objectForKey:@"useCustomAlpha"] ?: @(NO)) boolValue]) {
		alphaValue = [([prefs objectForKey:@"alphaValue"] ?: @(kDefaultAlpha)) doubleValue];
	} else {
		alphaValue = kDefaultAlpha;
	}
	CGFloat finalAlpha = shouldHide ? 0.0f : alphaValue;

	NSTimeInterval duration;
	if ([([prefs objectForKey:@"useCustomDuration"] ?: @(NO)) boolValue]) {
		duration = [([prefs objectForKey:@"customDuration"] ?: @(kDefaultAnimDuration)) doubleValue];
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

%end

# pragma mark - Initialization

%ctor {
	prefs = [[HBPreferences alloc] initWithIdentifier:@"com.gabrielsiu.stickynoteprefs"];
	if (prefs) {
		if ([([prefs objectForKey:@"isEnabled"] ?: @(YES)) boolValue]) {
			%init(Tweak);
		}
	}
}