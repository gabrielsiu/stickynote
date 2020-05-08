#pragma mark - System Versioning

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#pragma mark - Setup

#define SETUP_NOTE() ({\
	noteVC = [[NoteViewController alloc] initWithPrefs:prefs screenSize:self.frame.size];\
	UIPanGestureRecognizer *fingerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];\
	[noteVC.noteView addGestureRecognizer:fingerDrag];\
	[self addSubview:noteVC.noteView];\
	[[self _viewControllerForAncestor] addChildViewController:noteVC];\
})

#define SETUP_HIDE_BUTTON() ({\
	if (!noteVC.noteView)\
		return;\
	hideButton = [UIButton buttonWithType:UIButtonTypeCustom];\
	[hideButton setImage:[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-note.png"]] forState:UIControlStateNormal];\
	[hideButton addTarget:self action:@selector(didPressHideButton:) forControlEvents:UIControlEventTouchUpInside];\
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];\
	[hideButton addGestureRecognizer:longPress];\
	[self addSubview:hideButton];\
	NSInteger buttonSize;\
	if ([([prefs objectForKey:@"useCustomButtonSize"] ?: @(NO)) boolValue]) {\
		buttonSize = [prefs nonZeroIntegerForKey:@"buttonSize" fallback:1.2f*kIconSize];\
	} else {\
		buttonSize = 1.2f*kIconSize;\
	}\
	NSInteger xOffset = [([prefs objectForKey:@"xOffset"] ?: @0) intValue];\
	NSInteger yOffset = [([prefs objectForKey:@"yOffset"] ?: @0) intValue];\
	hideButton.translatesAutoresizingMaskIntoConstraints = NO;\
	[hideButton.widthAnchor constraintEqualToConstant:buttonSize].active = YES;\
	[hideButton.heightAnchor constraintEqualToConstant:buttonSize].active = YES;\
	[hideButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:xOffset].active = YES;\
	[hideButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-yOffset].active = YES;\
})

#pragma mark - Actions

#define DID_PRESS_HIDE_BUTTON() ({\
	BOOL shouldHide = !noteVC.noteView.isHidden;\
	/* Determine animation duration */\
	NSTimeInterval duration;\
	if ([([prefs objectForKey:@"useCustomDuration"] ?: @(NO)) boolValue])\
		duration = [([prefs objectForKey:@"customDuration"] ?: @(kDefaultAnimDuration)) doubleValue];\
	else\
		duration = kDefaultAnimDuration;\
	/* Determine animation type */\
	NSInteger animationNum = [([prefs objectForKey:@"animationType"] ?: @0) intValue];\
	UIViewAnimationOptions animationType;\
	switch (animationNum) {\
		case 1:\
			animationType = UIViewAnimationOptionTransitionCurlUp;\
			break;\
		case 2:\
			animationType = UIViewAnimationOptionTransitionFlipFromLeft;\
			break;\
		case 3:\
			animationType = UIViewAnimationOptionTransitionFlipFromRight;\
			break;\
		case 4:\
			animationType = UIViewAnimationOptionTransitionFlipFromTop;\
			break;\
		case 5:\
			animationType = UIViewAnimationOptionTransitionFlipFromBottom;\
			break;\
		default:\
			animationType = UIViewAnimationOptionTransitionCrossDissolve;\
	}\
	/* If Curl animation is selected, use the curlDown animation for showing the note */\
	if (!shouldHide && animationNum == 1) {\
		[UIView transitionWithView:noteVC.noteView duration:duration options:UIViewAnimationOptionTransitionCurlDown animations:^{\
			[noteVC.noteView setHidden:NO];\
			[noteVC.noteView setAlpha:1.0f];\
		} completion:^(BOOL finished) {\
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"stickynote_hidden"];\
			[[NSUserDefaults standardUserDefaults] synchronize];\
		}];\
		return;\
	}\
	/* Show/Hide Animation */\
	if (!shouldHide)\
		[noteVC.noteView setHidden:NO];\
	[UIView transitionWithView:noteVC.noteView duration:duration options:animationType animations:^{\
		if (shouldHide) {\
			/* Unable to animate the hiding of a view using transitionWithView, so just animate the transition to a small alpha value, then hide it after */\
			[noteVC.noteView setAlpha:0.01f];\
		} else {\
			[noteVC.noteView setAlpha:1.0f];\
		}\
	} completion:^(BOOL finished) {\
		[[NSUserDefaults standardUserDefaults] setBool:shouldHide forKey:@"stickynote_hidden"];\
		[[NSUserDefaults standardUserDefaults] synchronize];\
		if (shouldHide)\
			[noteVC.noteView setHidden:YES];\
	}];\
})

// Handle pan gesture for dragging the note around
// Adapted from https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_uikit_gestures/handling_pan_gestures
#define HANDLE_DRAG(sender) ({\
	if (!sender.view)\
		return;\
	UIView *noteView = sender.view;\
	CGPoint translation = [sender translationInView:noteView.superview];\
	if (sender.state == UIGestureRecognizerStateBegan)\
		initialCenter = noteView.center;\
	if (sender.state == UIGestureRecognizerStateEnded)\
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(CGPointMake(noteView.frame.origin.x, noteView.frame.origin.y)) forKey:@"stickynote_position"];\
		[[NSUserDefaults standardUserDefaults] synchronize];\
	if (sender.state != UIGestureRecognizerStateCancelled) {\
		noteView.center = CGPointMake(initialCenter.x + translation.x, initialCenter.y + translation.y);\
		if (useButtonsHideDelay && !noteVC.isEditing && noteVC.noteView.privacyViewIsHidden) {\
			[noteVC.noteView showButtons];\
			[noteVC.noteView startTimer];\
		}\
	} else {\
		noteView.center = initialCenter;\
	}\
})

// Handle long press gesture for returning note to center of screen
#define HANDLE_LONG_PRESS(sender) ({\
	if (sender.state == UIGestureRecognizerStateBegan) {\
		[UIView animateWithDuration:0.3f animations:^{\
			noteVC.noteView.center = CGPointMake(noteVC.noteView.superview.frame.size.width / 2, noteVC.noteView.superview.frame.size.height / 2);\
		} completion:^(BOOL finished) {\
			[[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(CGPointMake(noteVC.noteView.frame.origin.x, noteVC.noteView.frame.origin.y)) forKey:@"stickynote_position"];\
			[[NSUserDefaults standardUserDefaults] synchronize];\
		}];\
	}\
})