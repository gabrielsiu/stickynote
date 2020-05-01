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
	CGFloat noteX = (self.frame.size.width - width) / 2.0f;
	CGFloat noteY = (self.frame.size.height - height) / 2.0f;
	noteView = [[Note alloc] initWithFrame:CGRectMake(noteX, noteY, width, height) prefs:prefs];

	UIPanGestureRecognizer *fingerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
	[noteView addGestureRecognizer:fingerDrag];

	[self addSubview:noteView];
}

%new
- (void)setupHideButton {
	if (!noteView) { return; }
	hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[hideButton setImage:[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-note.png"]] forState:UIControlStateNormal];

	[hideButton addTarget:self action:@selector(didPressHideButton:) forControlEvents:UIControlEventTouchUpInside];
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[hideButton addGestureRecognizer:longPress];

	[self addSubview:hideButton];
	NSInteger xOffset = [([prefs objectForKey:@"xOffset"] ?: @0) intValue];
	NSInteger yOffset = [([prefs objectForKey:@"yOffset"] ?: @0) intValue];
	hideButton.translatesAutoresizingMaskIntoConstraints = NO;
	[hideButton.widthAnchor constraintEqualToConstant:1.2f*kIconSize].active = YES;
    [hideButton.heightAnchor constraintEqualToConstant:1.2f*kIconSize].active = YES;
    [hideButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:xOffset].active = YES;
    [hideButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-yOffset].active = YES;
}


# pragma mark Actions

%new
- (void)didPressHideButton:(UIButton *)sender {
	BOOL shouldHide = !noteView.isHidden;

	// Determine animation duration
	NSTimeInterval duration;
	if ([([prefs objectForKey:@"useCustomDuration"] ?: @(NO)) boolValue]) {
		duration = [([prefs objectForKey:@"customDuration"] ?: @(kDefaultAnimDuration)) doubleValue];
	} else {
		duration = kDefaultAnimDuration;
	}

	// Determine animation type
	NSInteger animationNum = [([prefs objectForKey:@"animationType"] ?: @0) intValue];
	UIViewAnimationOptions animationType;
	switch (animationNum) {
		case 1:
			animationType = UIViewAnimationOptionTransitionCurlUp;
			break;
		case 2:
			animationType = UIViewAnimationOptionTransitionFlipFromLeft;
			break;
		case 3:
			animationType = UIViewAnimationOptionTransitionFlipFromRight;
			break;
		case 4:
			animationType = UIViewAnimationOptionTransitionFlipFromTop;
			break;
		case 5:
			animationType = UIViewAnimationOptionTransitionFlipFromBottom;
			break;
		default:
			animationType = UIViewAnimationOptionTransitionCrossDissolve;
	}

	// If Curl animation is selected, use the curlDown animation for showing the note
	if (!shouldHide && animationNum == 1) {
		[UIView transitionWithView:noteView duration:duration options:UIViewAnimationOptionTransitionCurlDown animations:^{
			[noteView setHidden:NO];
			[noteView setAlpha:1.0f];
		} completion:nil];
		return;
	}

	// Show/Hide Animation
	[UIView transitionWithView:noteView duration:duration options:animationType animations:^{
		if (shouldHide) {
			// Unable to animate the hiding of a view using transitionWithView, so just animate the transition to a small alpha value, then hide it after
			[noteView setAlpha:0.01f];
		} else {
			[noteView setHidden:NO];
			[noteView setAlpha:1.0f];
		}
    } completion:^(BOOL finished) {
		if (shouldHide) {
			[noteView setHidden:YES];
		}
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