#import "HBPreferences+Helpers.h"
#import "Constants.h"
#import "Note.h"
#import "SparkColourPickerUtils.h"

@interface Note ()
@property (nonatomic) BOOL useButtonHiding;
@property (nonatomic) NSInteger buttonsHideDelay;
@property (nonatomic, strong) NSTimer *hideButtonsTimer;
@property (nonatomic, strong) HBPreferences *prefs;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIView *privacyView;
@property (nonatomic, strong) UIView *buttonsContainerView;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation Note

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences useButtonHiding:(BOOL)useButtonHiding {
	self = [super initWithFrame:frame];
	if (self) {
		self.prefs = preferences;
		[self setupStyle];
		[self setupButtons];
		[self setupTextView];
		[self setupPrivacyView];
		self.useButtonHiding = useButtonHiding;
		if (self.useButtonHiding) {
			[self setupTapGesture];
		}
	}
	return self;
}

#pragma mark - Setup

- (void)setupStyle {
	// Alpha & Note Color
	double alphaValue;
	if ([([self.prefs objectForKey:@"useCustomAlpha"] ?: @(NO)) boolValue]) {
		alphaValue = [([self.prefs objectForKey:@"alphaValue"] ?: @(kDefaultAlpha)) doubleValue];
	} else {
		alphaValue = kDefaultAlpha;
	}
	UIColor *noteColor;
	if ([([self.prefs objectForKey:@"useCustomNoteColor"] ?: @(NO)) boolValue]) {
		noteColor = [self colorForKey:@"noteColor" fallbackNum:13];
	} else {
		noteColor = UIColor.yellowColor;
	}
	self.backgroundColor = [noteColor colorWithAlphaComponent:alphaValue];

	// Corner Radius
	if ([self.prefs valueExistsForKey:@"cornerRadius"]) {
		self.layer.cornerRadius = [([self.prefs objectForKey:@"cornerRadius"] ?: @(kDefaultCornerRadius)) intValue];
	} else {
		self.layer.cornerRadius = kDefaultCornerRadius;
	}

	// Note Shadow
	if ([([self.prefs objectForKey:@"useNoteShadow"] ?: @(YES)) boolValue]) {
		self.layer.masksToBounds = NO;
		self.layer.shadowOffset = CGSizeMake(-5, 5);
		self.layer.shadowRadius = 5;
		self.layer.shadowOpacity = 0.5;
	}
}

- (void)setupButtons {
	// Determine custom button color, if chosen
	UIColor *buttonColor;
	if ([([self.prefs objectForKey:@"useCustomFontColor"] ?: @(NO)) boolValue]) {
		buttonColor = [self colorForKey:@"fontColor" fallbackNum:0];
	} else {
		buttonColor = UIColor.blackColor;
	}

	// Determine top button size
	NSInteger buttonSize;
	if ([([self.prefs objectForKey:@"useCustomTopButtonSize"] ?: @(NO)) boolValue]) {
		buttonSize = [self.prefs nonZeroIntegerForKey:@"topButtonSize" fallback:kIconSize];
	} else {
		buttonSize = kIconSize;
	}

	// Determine margins
	NSInteger topMargin = [([self.prefs objectForKey:@"textViewTopMargin"] ?: @0) intValue];
	NSInteger leftMargin = [([self.prefs objectForKey:@"textViewLeftMargin"] ?: @0) intValue];
	NSInteger rightMargin = [([self.prefs objectForKey:@"textViewRightMargin"] ?: @0) intValue];

	// Set up buttons container view
	self.buttonsContainerView = [[UIView alloc] initWithFrame:CGRectMake(topMargin, leftMargin, self.frame.size.width - leftMargin - rightMargin, buttonSize)];
	self.buttonsContainerView.backgroundColor = UIColor.clearColor;
	[self addSubview:self.buttonsContainerView];

	// Set up navigation bar for the buttons
	UINavigationBar *buttonsBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width - leftMargin - rightMargin, buttonSize)];
	buttonsBar.userInteractionEnabled = NO;

	// Make navigation bar transparent
	[buttonsBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
	buttonsBar.shadowImage = [UIImage new];
	buttonsBar.translucent = YES;
	UINavigationItem *buttonsItem = [[UINavigationItem alloc] init];

	// Set up navigation bar items
	if ([([self.prefs objectForKey:@"allowSharing"] ?: @(NO)) boolValue]) {
		self.shareButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
		buttonsItem.leftBarButtonItem = self.shareButtonItem;
	}
	self.clearButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
	buttonsItem.rightBarButtonItem = self.clearButtonItem;
	
	buttonsBar.items = @[buttonsItem];
	buttonsBar.translatesAutoresizingMaskIntoConstraints = NO;
	[self.buttonsContainerView addSubview:buttonsBar];
	[buttonsBar.topAnchor constraintEqualToAnchor:self.buttonsContainerView.topAnchor].active = YES;
	[buttonsBar.bottomAnchor constraintEqualToAnchor:self.buttonsContainerView.bottomAnchor].active = YES;
	[buttonsBar.leadingAnchor constraintEqualToAnchor:self.buttonsContainerView.leadingAnchor].active = YES;
	[buttonsBar.trailingAnchor constraintEqualToAnchor:self.buttonsContainerView.trailingAnchor].active = YES;

	// Set up actual buttons
	if ([([self.prefs objectForKey:@"allowSharing"] ?: @(NO)) boolValue]) {
		UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[shareButton setImage:[[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-share.png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
		[shareButton addTarget:self action:@selector(didPressShareButton:) forControlEvents:UIControlEventTouchUpInside];
		[self.buttonsContainerView addSubview:shareButton];
		shareButton.tintColor = buttonColor;
		shareButton.translatesAutoresizingMaskIntoConstraints = NO;
		[shareButton.topAnchor constraintEqualToAnchor:self.buttonsContainerView.topAnchor].active = YES;
		[shareButton.leadingAnchor constraintEqualToAnchor:self.buttonsContainerView.leadingAnchor].active = YES;
		[shareButton.widthAnchor constraintEqualToConstant:buttonSize].active = YES;
		[shareButton.heightAnchor constraintEqualToConstant:buttonSize].active = YES;
	}
	UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[clearButton setImage:[[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-clear.png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	[clearButton addTarget:self action:@selector(didPressClearButton:) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonsContainerView addSubview:clearButton];
	clearButton.tintColor = buttonColor;
	clearButton.translatesAutoresizingMaskIntoConstraints = NO;
	[clearButton.topAnchor constraintEqualToAnchor:self.buttonsContainerView.topAnchor].active = YES;
	[clearButton.trailingAnchor constraintEqualToAnchor:self.buttonsContainerView.trailingAnchor].active = YES;
	[clearButton.widthAnchor constraintEqualToConstant:buttonSize].active = YES;
	[clearButton.heightAnchor constraintEqualToConstant:buttonSize].active = YES;
}

- (void)setupTextView {
	// Initialize the text view with a temporary frame; will adjust using auto layout constraints later
	self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) textContainer:nil];
	self.textView.backgroundColor = [UIColor clearColor];

	UIColor *fontColor;
	if ([([self.prefs objectForKey:@"useCustomFontColor"] ?: @(NO)) boolValue]) {
		fontColor = [self colorForKey:@"fontColor" fallbackNum:0];
	} else {
		fontColor = UIColor.blackColor;
	}
	self.textView.textColor = fontColor;

	NSInteger fontSize;
	if ([self.prefs valueExistsForKey:@"fontSize"]) {
		fontSize = [([self.prefs objectForKey:@"fontSize"] ?: @(kDefaultFontSize)) intValue];
	} else {
		fontSize = kDefaultFontSize;
	}

	if ([([self.prefs objectForKey:@"useCustomFont"] ?: @(NO)) boolValue]) {
		NSString *fontName = [self.prefs objectForKey:@"customFont"] ?: @"";
		if (![fontName isEqualToString:@""]) {
			self.textView.font = [UIFont fontWithName:fontName size:fontSize];
		} else {
			self.textView.font = [UIFont systemFontOfSize:fontSize];
		}
	} else {
		self.textView.font = [UIFont systemFontOfSize:fontSize];
	}

	// Setup 'Done' button on keyboard
	UIToolbar *doneButtonView = [[UIToolbar alloc] init];
	[doneButtonView sizeToFit];
	UIBarButtonItem *bulletItem = [[UIBarButtonItem alloc] initWithTitle:@"•" style:UIBarButtonItemStylePlain target:self action:@selector(didPressBulletButton:)];
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDoneButton:)];
	[doneButtonView setItems:[NSArray arrayWithObjects:bulletItem, flexibleSpace, doneButton, nil]];
	self.textView.inputAccessoryView = doneButtonView;

	[self restoreSavedText];
	[self addSubview:self.textView];

	NSInteger bottomMargin = [([self.prefs objectForKey:@"textViewBottomMargin"] ?: @0) intValue];
	NSInteger leftMargin = [([self.prefs objectForKey:@"textViewLeftMargin"] ?: @0) intValue];
	NSInteger rightMargin = [([self.prefs objectForKey:@"textViewRightMargin"] ?: @0) intValue];
	self.textView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.textView.topAnchor constraintEqualToAnchor:self.buttonsContainerView.bottomAnchor].active = YES;
	[self.textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-bottomMargin].active = YES;
	[self.textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:leftMargin].active = YES;
	[self.textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-rightMargin].active = YES;
}

- (void)setupPrivacyView {
	self.privacyView = [[UIView alloc] initWithFrame:self.bounds];
	self.privacyView.backgroundColor = [UIColor clearColor];
	if ([self.prefs valueExistsForKey:@"cornerRadius"]) {
		self.privacyView.layer.cornerRadius = [([self.prefs objectForKey:@"cornerRadius"] ?: @(kDefaultCornerRadius)) intValue];
	} else {
		self.privacyView.layer.cornerRadius = kDefaultCornerRadius;
	}

	UIImage *lockIcon = [UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-lock.png"]];
	UIImageView *lockIconView = [[UIImageView alloc] initWithImage:[lockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
	UIColor *iconColor;
	if ([([self.prefs objectForKey:@"useCustomFontColor"] ?: @(NO)) boolValue]) {
		iconColor = [self colorForKey:@"fontColor" fallbackNum:0];
	} else {
		iconColor = UIColor.blackColor;
	}
	lockIconView.tintColor = iconColor;
	[self.privacyView addSubview:lockIconView];
	lockIconView.translatesAutoresizingMaskIntoConstraints = NO;
	[lockIconView.centerXAnchor constraintEqualToAnchor:self.privacyView.centerXAnchor].active = YES;
	[lockIconView.centerYAnchor constraintEqualToAnchor:self.privacyView.centerYAnchor].active = YES;
	[lockIconView.widthAnchor constraintEqualToConstant:2*kIconSize].active = YES;
	[lockIconView.heightAnchor constraintEqualToConstant:2*kIconSize].active = YES;
	
	[self addSubview:self.privacyView];
	[self.privacyView setHidden:YES];
}

- (void)setupTapGesture {
	self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonsBarTapped:)];
	[self addGestureRecognizer:self.tapRecognizer];
	self.buttonsHideDelay = [self.prefs nonZeroIntegerForKey:@"buttonsHideDelay" fallback:3];
	[self.buttonsContainerView setAlpha:0];
	[self.buttonsContainerView setHidden:YES];
}

- (void)restoreSavedText {
	NSString *savedText = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"stickynote_text"];
	if (savedText) {
		// When restoring saved text after a respring, if no text was saved, the text view will be scrollable
		// This is just a quick fix to prevent that, I may or may not investigate the root cause of the issue later
		if ([savedText isEqualToString:@""]) {
			self.textView.text = @".";
		}
		self.textView.text = savedText;
	}
}

- (void)setTextViewDelegate:(id)delegate {
	self.textView.delegate = delegate;
}

#pragma mark - Actions

- (void)buttonsBarTapped:(UITapGestureRecognizer *)recognizer {
	if (self.buttonsContainerView.isHidden) {
		[self showButtons];
		[self startTimer];
	}
}

- (void)didPressShareButton:(UIButton *)sender {
	[self.delegate didPressShareButton:self];
}

- (void)didPressClearButton:(UIButton *)sender {
	[self.delegate didPressClearButton:self];
}

- (void)didPressBulletButton:(UIButton *)sender {
	self.textView.text = [self.textView.text stringByAppendingString:@"• "];
}

- (void)didPressDoneButton:(UIButton *)sender {
	[self dismissKeyboard];
}

- (void)dismissKeyboard {
	[self.textView resignFirstResponder];
}

#pragma mark - Public Methods

- (void)saveText {
	[[NSUserDefaults standardUserDefaults] setObject:self.textView.text forKey:@"stickynote_text"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearTextView {
	self.textView.text = @"";
	[self saveText];
}

- (NSString *)getText {
	return self.textView.text;
}

- (BOOL)privacyViewIsHidden {
	return self.privacyView.isHidden;
}

- (void)hidePrivacyView {
	[self restoreSavedText];
	[self.buttonsContainerView setHidden:NO];
	[self.privacyView setHidden:YES];
	[self dismissKeyboard];
	if (self.useButtonHiding)
		self.tapRecognizer.enabled = YES;
}

- (void)showPrivacyView {
	self.textView.text = @"";
	[self.buttonsContainerView setHidden:YES];
	[self.privacyView setHidden:NO];
	if (self.useButtonHiding)
		self.tapRecognizer.enabled = NO;
}

- (void)startTimer {
	[self stopTimer];
	self.hideButtonsTimer = [NSTimer scheduledTimerWithTimeInterval:self.buttonsHideDelay target:self selector:@selector(hideButtons) userInfo:nil repeats:NO];
}

- (void)stopTimer {
	[self.hideButtonsTimer invalidate];
	self.hideButtonsTimer = nil;
}

- (void)hideButtons {
	[UIView animateWithDuration:kDefaultAnimDuration animations:^{
		[self.buttonsContainerView setAlpha:0];
	} completion:^(BOOL finished) {
		[self.buttonsContainerView setHidden:YES];
	}];
}

- (void)showButtons {
	[self.buttonsContainerView setHidden:NO];
	[UIView animateWithDuration:kDefaultAnimDuration animations:^{
		[self.buttonsContainerView setAlpha:1.0f];
	} completion:nil];
}

#pragma mark - Private Helpers

- (UIColor *)colorForKey:(NSString *)key fallbackNum:(NSInteger)fallback {
	NSInteger colorNum = [([self.prefs objectForKey:key] ?: @(fallback)) intValue];
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