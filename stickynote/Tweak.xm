#import <Cephei/HBPreferences.h>
#import "HBPreferences+Helpers.h"
#import "Macros.h"
#import "Constants.h"
#import "NoteViewController.h"

#pragma mark - Interfaces

@interface SBLockStateAggregator : NSObject
+ (id)sharedInstance;
- (unsigned long long)lockState;
@end

@interface SBFTouchPassThroughView : UIView
@end

#pragma mark iOS 13

@interface CSCoverSheetViewBase : SBFTouchPassThroughView

- (UIViewController *)_viewControllerForAncestor;
- (void)didMoveToSuperview;

- (void)didPressHideButton:(UIButton *)sender;
- (void)handleDrag:(UIPanGestureRecognizer *)sender;
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender;

@end

#pragma mark iOS 12

@interface SBDashBoardViewBase : SBFTouchPassThroughView

- (UIViewController *)_viewControllerForAncestor;
- (void)didMoveToSuperview;

- (void)didPressHideButton:(UIButton *)sender;
- (void)handleDrag:(UIPanGestureRecognizer *)sender;
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender;

@end

#pragma mark - Properties

HBPreferences *prefs;
NoteViewController *noteVC;
UIButton *hideButton;
CGPoint initialCenter;

// This boolean determines whether or not the Darwin notifications will be observed
// Initially set to NO, if a device passcode is enabled (determined during initilization) then it will be set to YES
BOOL passcodeEnabled = NO;

#pragma mark - iOS 13

%group iOS13
%hook CSCoverSheetViewBase

- (void)didMoveToSuperview {
	%orig;
	if (!noteVC) {
		if ([self.superview isMemberOfClass:[%c(CSMainPageView) class]]) {
			SETUP_NOTE();
			SETUP_HIDE_BUTTON();
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

%new
- (void)didPressHideButton:(UIButton *)sender {
	DID_PRESS_HIDE_BUTTON();
}

%new
- (void)handleDrag:(UIPanGestureRecognizer *)sender {
	HANDLE_DRAG(sender);
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
	HANDLE_LONG_PRESS(sender);
}

%end
%end

#pragma mark - iOS 12

%group iOS12
%hook SBDashBoardViewBase

- (void)didMoveToSuperview {
	%orig;
	if (!noteVC) {
		if ([self.superview isMemberOfClass:[%c(SBDashBoardMainPageView) class]]) {
			SETUP_NOTE();
			SETUP_HIDE_BUTTON();
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

%new
- (void)didPressHideButton:(UIButton *)sender {
	DID_PRESS_HIDE_BUTTON();
}

%new
- (void)handleDrag:(UIPanGestureRecognizer *)sender {
	HANDLE_DRAG(sender);
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
	HANDLE_LONG_PRESS(sender);
}

%end
%end

#pragma mark - Darwin Notification Callbacks

static void deviceLockStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// This callback only gets called when the actual lock status of the device changes (locked<->unlocked)
	// This callback will not get called at all if the device is not secured with a passcode
	if (!noteVC) { return; }
	[noteVC.noteView hidePrivacyView];
}

static void hasBlankedScreen(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// This callback gets called whenever the device screen turns on or off
	// Additionally, this callback gets called after a respring
	if (!noteVC) { return; }
	if (passcodeEnabled) {
		[noteVC.noteView showPrivacyView];
	}
}

#pragma mark - Initialization

%ctor {
	prefs = [[HBPreferences alloc] initWithIdentifier:@"com.gabrielsiu.stickynoteprefs"];
	if (prefs) {
		if ([([prefs objectForKey:@"isEnabled"] ?: @(YES)) boolValue]) {
			// Add Darwin notification observers if privacy mode is enabled
			if ([([prefs objectForKey:@"usePrivacyMode"] ?: @(NO)) boolValue]) {
				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, deviceLockStatusChanged, CFSTR("com.apple.springboard.DeviceLockStatusChanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, hasBlankedScreen, CFSTR("com.apple.springboard.hasBlankedScreen"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			}
			if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.0")) {
				%init(iOS13);
			} else {
				%init(iOS12);
			}
		}
	}
}