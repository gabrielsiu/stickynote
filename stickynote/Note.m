#import "HBPreferences+Helpers.h"
#import "Constants.h"
#import "Note.h"

@implementation Note

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences {
	self = [super initWithFrame:frame];
	if (self) {
		prefs = preferences;
		[self setupStyle];
		[self setupButtons];
		[self setupTextView];
		[self setupPrivacyView];
	}
	return self;
}

#pragma mark - Setup

- (void)setupStyle {
	double alphaValue;
	if ([([prefs objectForKey:@"useCustomAlpha"] ?: @(NO)) boolValue]) {
		alphaValue = [([prefs objectForKey:@"alphaValue"] ?: @(kDefaultAlpha)) doubleValue];
	} else {
		alphaValue = kDefaultAlpha;
	}
	UIColor *noteColor;
	if ([([prefs objectForKey:@"useCustomNoteColor"] ?: @(NO)) boolValue]) {
		noteColor = [self colorForKey:@"noteColor" fallbackNum:13];
	} else {
		noteColor = UIColor.yellowColor;
	}
	self.backgroundColor = [noteColor colorWithAlphaComponent:alphaValue];

	if ([prefs valueExistsForKey:@"cornerRadius"]) {
		self.layer.cornerRadius = [([prefs objectForKey:@"cornerRadius"] ?: @(kDefaultCornerRadius)) intValue];
	} else {
		self.layer.cornerRadius = kDefaultCornerRadius;
	}
	self.layer.masksToBounds = NO;
	self.layer.shadowOffset = CGSizeMake(-5, 5);
	self.layer.shadowRadius = 5;
	self.layer.shadowOpacity = 0.5;
}

- (void)setupButtons {
	// Determine custom icon color, if chosen
	UIColor *iconColor;
	if ([([prefs objectForKey:@"useCustomFontColor"] ?: @(NO)) boolValue]) {
		iconColor = [self colorForKey:@"fontColor" fallbackNum:0];
	} else {
		iconColor = UIColor.blackColor;
	}

	// Set up navigation bar for the buttons
	buttonsBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, kIconSize)];
	buttonsBar.tintColor = iconColor;

	// Make navigation bar transparent
	[buttonsBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
	buttonsBar.shadowImage = [UIImage new];
	buttonsBar.translucent = YES;
	UINavigationItem *buttonsItem = [[UINavigationItem alloc] init];

	// Set up share button
	UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[shareButton setImage:[[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-share.png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	[shareButton addTarget:self action:@selector(didPressShareButton:) forControlEvents:UIControlEventTouchUpInside];
	shareButton.translatesAutoresizingMaskIntoConstraints = NO;
	[shareButton.widthAnchor constraintEqualToConstant:kIconSize].active = YES;
	[shareButton.heightAnchor constraintEqualToConstant:kIconSize].active = YES;

	// Set up clear button
	UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[clearButton setImage:[[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-clear.png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	[clearButton addTarget:self action:@selector(didPressClearButton:) forControlEvents:UIControlEventTouchUpInside];
	clearButton.translatesAutoresizingMaskIntoConstraints = NO;
	[clearButton.widthAnchor constraintEqualToConstant:kIconSize].active = YES;
	[clearButton.heightAnchor constraintEqualToConstant:kIconSize].active = YES;

	// Add the buttons to the navigation bar
	self.shareButtonItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
	self.clearButtonItem = [[UIBarButtonItem alloc] initWithCustomView:clearButton];
	buttonsItem.leftBarButtonItem = self.shareButtonItem;
	buttonsItem.rightBarButtonItem = self.clearButtonItem;
	buttonsBar.items = @[buttonsItem];

	[self addSubview:buttonsBar];
}


- (void)setupTextView {
	textView = [[UITextView alloc] initWithFrame:CGRectMake(0, kIconSize, self.frame.size.width, self.frame.size.height - kIconSize) textContainer:nil];
	textView.backgroundColor = [UIColor clearColor];

	UIColor *fontColor;
	if ([([prefs objectForKey:@"useCustomFontColor"] ?: @(NO)) boolValue]) {
		fontColor = [self colorForKey:@"fontColor" fallbackNum:0];
	} else {
		fontColor = UIColor.blackColor;
	}
	textView.textColor = fontColor;

	NSInteger fontSize;
	if ([prefs valueExistsForKey:@"fontSize"]) {
		fontSize = [([prefs objectForKey:@"fontSize"] ?: @(kDefaultFontSize)) intValue];
	} else {
		fontSize = kDefaultFontSize;
	}
	textView.font = [UIFont systemFontOfSize:fontSize];

	// Setup 'Done' button on keyboard
	UIToolbar *doneButtonView = [[UIToolbar alloc] init];
	[doneButtonView sizeToFit];
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard:)];
	[doneButtonView setItems:[NSArray arrayWithObjects:flexibleSpace, doneButton, nil]];
	textView.inputAccessoryView = doneButtonView;

	[self restoreSavedText];
	[self addSubview:textView];
}

- (void)setupPrivacyView {
	privacyView = [[UIView alloc] initWithFrame:self.bounds];
	privacyView.backgroundColor = [UIColor clearColor];
	if ([prefs valueExistsForKey:@"cornerRadius"]) {
		privacyView.layer.cornerRadius = [([prefs objectForKey:@"cornerRadius"] ?: @(kDefaultCornerRadius)) intValue];
	} else {
		privacyView.layer.cornerRadius = kDefaultCornerRadius;
	}

	UIImage *lockIcon = [UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-lock.png"]];
	UIImageView *lockIconView = [[UIImageView alloc] initWithImage:[lockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
	UIColor *iconColor;
	if ([([prefs objectForKey:@"useCustomFontColor"] ?: @(NO)) boolValue]) {
		iconColor = [self colorForKey:@"fontColor" fallbackNum:0];
	} else {
		iconColor = UIColor.blackColor;
	}
	lockIconView.tintColor = iconColor;
	[privacyView addSubview:lockIconView];
	lockIconView.translatesAutoresizingMaskIntoConstraints = NO;
	[lockIconView.centerXAnchor constraintEqualToAnchor:privacyView.centerXAnchor].active = YES;
	[lockIconView.centerYAnchor constraintEqualToAnchor:privacyView.centerYAnchor].active = YES;
	[lockIconView.widthAnchor constraintEqualToConstant:2*kIconSize].active = YES;
	[lockIconView.heightAnchor constraintEqualToConstant:2*kIconSize].active = YES;
	
	[self addSubview:privacyView];
	[privacyView setHidden:YES];
}

- (void)restoreSavedText {
	NSData *noteTextData = [[NSUserDefaults standardUserDefaults] objectForKey:@"stickynote_text"];
	if (noteTextData) {
		NSString *savedText = [NSKeyedUnarchiver unarchiveObjectWithData:noteTextData];
		textView.text = savedText;
	}
}

- (void)setTextViewDelegate:(id)delegate {
	textView.delegate = delegate;
}

#pragma mark - Actions

- (void)didPressShareButton:(UIButton *)sender {
	[self.delegate didPressShareButton:self];
}

- (void)didPressClearButton:(UIButton *)sender {
	[self.delegate didPressClearButton:self];
}

- (void)dismissKeyboard:(UIButton *)sender {
	[textView resignFirstResponder];
}

#pragma mark - Public Methods

- (void)saveText {
	[[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:textView.text] forKey:@"stickynote_text"];
}

- (void)clearTextView {
	textView.text = @"";
	[self saveText];
}

- (NSString *)getText {
	return textView.text;
}

- (void)hidePrivacyView {
	[self restoreSavedText];
	[buttonsBar setHidden:NO];
	[privacyView setHidden:YES];
}

- (void)showPrivacyView {
	textView.text = @"";
	[buttonsBar setHidden:YES];
	[privacyView setHidden:NO];
}

#pragma mark - Private Helpers

- (UIColor *)colorForKey:(NSString *)key fallbackNum:(NSInteger)fallback {
	NSInteger colorNum = [([prefs objectForKey:key] ?: @(fallback)) intValue];
	UIColor *selectedColor;
	switch (colorNum) {
		case 0:
			selectedColor = UIColor.blackColor;
			break;
		case 1:
			selectedColor = UIColor.blueColor;
			break;
		case 2:
			selectedColor = UIColor.brownColor;
			break;
		case 3:
			selectedColor = UIColor.cyanColor;
			break;
		case 4:
			selectedColor = UIColor.darkGrayColor;
			break;
		case 5:
			selectedColor = UIColor.grayColor;
			break;
		case 6:
			selectedColor = UIColor.greenColor;
			break;
		case 7:
			selectedColor = UIColor.lightGrayColor;
			break;
		case 8:
			selectedColor = UIColor.magentaColor;
			break;
		case 9:
			selectedColor = UIColor.orangeColor;
			break;
		case 10:
			selectedColor = UIColor.purpleColor;
			break;
		case 11:
			selectedColor = UIColor.redColor;
			break;
		case 12:
			selectedColor = UIColor.whiteColor;
			break;
		case 13:
			selectedColor = UIColor.yellowColor;
			break;
		default:
			selectedColor = UIColor.blackColor;
	}
	return selectedColor;
}

@end