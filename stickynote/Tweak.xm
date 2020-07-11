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

@interface SBCoverSheetPresentationManager : NSObject
+ (id)sharedInstance;
- (id)dashBoardViewController;
- (id)coverSheetViewController;
@end

@interface SBDashBoardIdleTimerProvider : NSObject
- (void)addDisabledIdleTimerAssertionReason:(id)arg1;
- (void)removeDisabledIdleTimerAssertionReason:(id)arg1;
@end

#pragma mark iOS 13

@interface CSCoverSheetViewBase : SBFTouchPassThroughView
- (UIViewController *)_viewControllerForAncestor;
- (void)didMoveToSuperview;

- (void)didPressHideButton:(UIButton *)sender;
- (void)handleDrag:(UIPanGestureRecognizer *)sender;
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender;
@end

@interface SBDashBoardIdleTimerController : NSObject {
	SBDashBoardIdleTimerProvider *_dashBoardIdleTimerProvider;
}
@end

@interface CSCoverSheetViewController : UIViewController
- (id)idleTimerController;
@end

#pragma mark iOS 11 & 12

@interface SBDashBoardViewBase : SBFTouchPassThroughView
- (UIViewController *)_viewControllerForAncestor;
- (void)didMoveToSuperview;

- (void)didPressHideButton:(UIButton *)sender;
- (void)handleDrag:(UIPanGestureRecognizer *)sender;
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender;
@end

@interface SBDashBoardViewController : UIViewController {
	SBDashBoardIdleTimerProvider *_idleTimerProvider;
}
@end

#pragma mark - Properties

HBPreferences *prefs;
NoteViewController *noteVC;
UIButton *hideButton;
CGPoint initialCenter;
BOOL useButtonsHideDelay;

// This boolean determines whether or not the Darwin notifications will be observed
// Initially set to NO, if a device passcode is enabled (determined during initilization) then it will be set to YES
BOOL passcodeEnabled = NO;
// This boolean determines whether or not a respring has just occurred
// Initially set to YES, as soon as the device finishes respringing, it will be set to NO
// It is only used by the deviceLockStatusChanged callback, as a sign to immediately return if a respring has just occurred
BOOL respringOccurred = YES;

#pragma mark - iOS 13

%group iOS13

// Much credit & thanks to DGh0st for his implementation of disabling the lock screen idle timer
// This function (and the other idle timer logic) is adapted from DGh0st's tweak 'FLEXall'
// Source code for FLEXall: https://github.com/DGh0st/FLEXall
static SBDashBoardIdleTimerProvider *getIdleTimerProvider13() {
	SBCoverSheetPresentationManager *presentationManager = [%c(SBCoverSheetPresentationManager) sharedInstance];
	SBDashBoardIdleTimerProvider *_idleTimerProvider = nil;
	if ([presentationManager respondsToSelector:@selector(coverSheetViewController)]) {
		SBDashBoardIdleTimerController *dashboardIdleTimerController = [[presentationManager coverSheetViewController] idleTimerController];
		_idleTimerProvider = [dashboardIdleTimerController valueForKey:@"_dashBoardIdleTimerProvider"];
	}
	return _idleTimerProvider;
}

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
			
			// If enabled, start observing notifications for disabling the lock screen idle timer
			if ([([prefs objectForKey:@"disableLockscreenAutoLock"] ?: @(NO)) boolValue]) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveIdleTimerNotification:) name:@"stickynote_idletimer" object:nil];
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

%new
- (void)receiveIdleTimerNotification:(NSNotification *)notification {
	HANDLE_IDLE_TIMER_NOTIFICATION_13();
}

%end
%end

#pragma mark - iOS 11 & 12

%group iOS11and12

// Much credit & thanks to DGh0st for his implementation of disabling the lock screen idle timer
// This function (and the other idle timer logic) is adapted from DGh0st's tweak 'FLEXall'
// Source code for FLEXall: https://github.com/DGh0st/FLEXall
static SBDashBoardIdleTimerProvider *getIdleTimerProvider12() {
	SBCoverSheetPresentationManager *presentationManager = [%c(SBCoverSheetPresentationManager) sharedInstance];
	SBDashBoardIdleTimerProvider *_idleTimerProvider = nil;
	if ([presentationManager respondsToSelector:@selector(dashBoardViewController)]) {
		SBDashBoardViewController *dashBoardViewController = [presentationManager dashBoardViewController];
		_idleTimerProvider = [dashBoardViewController valueForKey:@"_idleTimerProvider"];
	}
	return _idleTimerProvider;
}

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

			// If enabled, start observing notifications for disabling the lock screen idle timer
			if ([([prefs objectForKey:@"disableLockscreenAutoLock"] ?: @(NO)) boolValue]) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveIdleTimerNotification:) name:@"stickynote_idletimer" object:nil];
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

%new
- (void)receiveIdleTimerNotification:(NSNotification *)notification {
	HANDLE_IDLE_TIMER_NOTIFICATION_12();
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
	// Save the contents of the note when the screen turns off, but only if there's text there
	if (![[noteVC.noteView getText] isEqualToString:@""]) {
		[noteVC.noteView saveText];
	}
	// Upon waking the device from sleep, this will be the last callback called, so show the privacy view if a passcode is enabled
	if (passcodeEnabled) {
		[noteVC.noteView showPrivacyView];
	}
}

#pragma mark - Lock Screen Idle Timer


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
				%init(iOS11and12);
			}
		}
	}
}