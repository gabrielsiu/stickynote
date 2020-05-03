#import <Cephei/HBPreferences.h>
#import "Constants.h"
#import "HBPreferences+Helpers.h"
#import "Note.h"
#import "NoteViewController.h"

# pragma mark - Interfaces

@interface SBLockStateAggregator : NSObject

+ (id)sharedInstance;
- (unsigned long long)lockState;

@end

@interface SBFTouchPassThroughView : UIView
@end

@interface CSCoverSheetViewBase : SBFTouchPassThroughView

- (void)didMoveToSuperview;

- (void)setupNote;
- (void)setupHideButton;
- (void)setupPrivacyView;
- (void)didPressHideButton:(UIButton *)sender;
- (void)handleDrag:(UIPanGestureRecognizer *)sender;

@end

HBPreferences *prefs;
NoteViewController *noteVC;
UIButton *hideButton;
CGPoint initialCenter;

// This boolean determines whether or not the Darwin notifications will be observed
// Initially set to NO, if a device passcode is enabled (determined during initilization) then it will be set to YES
BOOL passcodeEnabled = NO;

# pragma mark - Tweak

%group Tweak

%hook CSCoverSheetViewBase

- (void)didMoveToSuperview {
	%orig;
	if (!noteVC) {
		if ([self.superview isMemberOfClass:[%c(CSMainPageView) class]]) {
			[self setupNote];
			[self setupHideButton];

			// If the device is secured with a passcode, enable the Darwin notifications
			if ([[%c(SBLockStateAggregator) sharedInstance] lockState] != 0) {
				passcodeEnabled = YES;
			} else {
				// Else, hide the privacy view and remove the observers
				[noteVC.noteView hidePrivacyView];
				CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CFSTR("com.apple.springboard.DeviceLockStatusChanged"), NULL);
				CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CFSTR("com.apple.springboard.hasBlankedScreen"), NULL);
			}
		}
	}
}

# pragma mark Setup

%new
- (void)setupNote {
	noteVC = [[NoteViewController alloc] initWithPrefs:prefs screenSize:self.frame.size];
	UIPanGestureRecognizer *fingerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
	[noteVC.noteView addGestureRecognizer:fingerDrag];
	[self addSubview:noteVC.noteView];
}

%new
- (void)setupHideButton {
	if (!noteVC.noteView) { return; }
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
	BOOL shouldHide = !noteVC.noteView.isHidden;

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
		[UIView transitionWithView:noteVC.noteView duration:duration options:UIViewAnimationOptionTransitionCurlDown animations:^{
			[noteVC.noteView setHidden:NO];
			[noteVC.noteView setAlpha:1.0f];
		} completion:nil];
		return;
	}

	// Show/Hide Animation
	[UIView transitionWithView:noteVC.noteView duration:duration options:animationType animations:^{
		if (shouldHide) {
			// Unable to animate the hiding of a view using transitionWithView, so just animate the transition to a small alpha value, then hide it after
			[noteVC.noteView setAlpha:0.01f];
		} else {
			[noteVC.noteView setHidden:NO];
			[noteVC.noteView setAlpha:1.0f];
		}
    } completion:^(BOOL finished) {
		if (shouldHide) {
			[noteVC.noteView setHidden:YES];
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
			noteVC.noteView.center = CGPointMake(noteVC.noteView.superview.frame.size.width / 2, noteVC.noteView.superview.frame.size.height / 2);
		} completion:NULL];
	}
}

# pragma mark - Darwin Notification Callbacks

static void deviceLockStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// This callback only gets called when the actual lock status of the device changes (locked<->unlocked)
	// This callback will not get called at all if the device is not secured with a passcode
	[noteVC.noteView hidePrivacyView];
}

static void hasBlankedScreen(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// This callback gets called whenever the device screen turns on or off
	// Additionally, this callback gets called after a respring
	if (passcodeEnabled) {
		[noteVC.noteView showPrivacyView];
	}
}

%end

%end

# pragma mark - Initialization

%ctor {
	prefs = [[HBPreferences alloc] initWithIdentifier:@"com.gabrielsiu.stickynoteprefs"];
	if (prefs) {
		if ([([prefs objectForKey:@"isEnabled"] ?: @(YES)) boolValue]) {
			// Add Darwin notification observers if privacy mode is enabled
			if ([([prefs objectForKey:@"usePrivacyMode"] ?: @(NO)) boolValue]) {
				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, deviceLockStatusChanged, CFSTR("com.apple.springboard.DeviceLockStatusChanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, hasBlankedScreen, CFSTR("com.apple.springboard.hasBlankedScreen"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			}
			%init(Tweak);
		}
	}
}