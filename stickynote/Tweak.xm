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
// This boolean determines whether or not a respring has just occurred
// Initially set to YES, as soon as the device finishes respringing, it will be set to NO
// It is only used by the deviceLockStatusChanged callback, as a sign to immediately return if a respring has just occurred
BOOL respringOccurred = YES;

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

// This callback only gets called when the actual lock status of the device changes (locked<->unlocked)
// This callback will not get called at all if the device is not secured with a passcode
static void deviceLockStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (!noteVC) { return; }
	// This is admittedly not a very robust solution; the problem is that from my experience, after a respring, the deviceLockStatusChanged callback occurs after the hasBlankedScreen callback
	// This leads to the privacy view not showing immediately after a respring, even if it is enabled (though you can unlock & lock the device to get it to appear)
	// Therefore just use the respringOccurred boolean to ignore this callback the first time it is called (which will always be right after a respring)
	if (respringOccurred) {
		respringOccurred = NO;
		return;
	}
	[noteVC.noteView hidePrivacyView];
}

// This callback gets called whenever the device screen turns on or off
static void hasBlankedScreen(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (!noteVC) { return; }
	// Upon waking the device from sleep, this will be the last callback called, so show the privacy view if a passcode is enabled
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