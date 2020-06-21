#import "HBPreferences+Helpers.h"
#import "Constants.h"
#import "Note.h"

@interface Note ()
@property (nonatomic) BOOL useButtonHiding;
@property (nonatomic) NSInteger buttonsHideDelay;
@property (nonatomic, strong) NSTimer *hideButtonsTimer;
@property (nonatomic, strong) HBPreferences *prefs;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIView *privacyView;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation Note

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences useButtonHiding:(BOOL)useButtonHiding {
	self = [super initWithFrame:frame];
	if (self) {
		self.prefs = preferences;
		[self setupStyle];
		[self setupTopBar];
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
	self.clipsToBounds = YES;

	// Alpha & Note Color
	double alphaValue;
	if ([([self.prefs objectForKey:@"useCustomAlpha"] ?: @(NO)) boolValue]) {
		alphaValue = [([self.prefs objectForKey:@"alphaValue"] ?: @(kDefaultAlpha)) doubleValue];
	} else {
		alphaValue = kDefaultAlpha;
	}
	UIColor *noteColor;
	if ([([self.prefs objectForKey:@"useCustomNoteColor"] ?: @(NO)) boolValue]) {
		noteColor = [self colorForKey:@"customNoteColor" fallbackColorHex:@"#ffff00"];
	} else {
		noteColor = UIColor.yellowColor;
	}
	self.backgroundColor = [noteColor colorWithAlphaComponent:alphaValue];

	// Corner Radius
	NSInteger cornerRadius;
	if ([self.prefs valueExistsForKey:@"cornerRadius"]) {
		cornerRadius = [([self.prefs objectForKey:@"cornerRadius"] ?: @(kDefaultCornerRadius)) intValue];
	} else {
		cornerRadius = kDefaultCornerRadius;
	}
	self.layer.cornerRadius = cornerRadius;

	// Blur Effect
	if ([([self.prefs objectForKey:@"useBlurEffect"] ?: @(YES)) boolValue]) {
		NSInteger blurStyleNum = [([self.prefs objectForKey:@"blurStyle"] ?: @3) intValue];
		UIBlurEffectStyle blurStyle;
		switch (blurStyleNum) {
			case 0:
				blurStyle = UIBlurEffectStyleExtraLight;
				break;
			case 1:
				blurStyle = UIBlurEffectStyleLight;
				break;
			case 2:
				blurStyle = UIBlurEffectStyleDark;
				break;
			case 3:
				blurStyle = UIBlurEffectStyleRegular;
				break;
			case 4:
				blurStyle = UIBlurEffectStyleProminent;
				break;
			default:
				blurStyle = UIBlurEffectStyleRegular;
		}
		UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
		UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		visualEffectView.frame = self.bounds;
		visualEffectView.layer.cornerRadius = cornerRadius;
		visualEffectView.clipsToBounds = YES;
		[self addSubview:visualEffectView];
	}

	// Note Shadow
	if ([([self.prefs objectForKey:@"useNoteShadow"] ?: @(NO)) boolValue]) {
		self.layer.masksToBounds = NO;
		self.layer.shadowOffset = CGSizeMake(-5, 5);
		self.layer.shadowRadius = cornerRadius;
		self.layer.shadowOpacity = 0.5;
	}
}

- (void)setupTopBar {
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

	// Determine top bar accent color, if chosen
	UIColor *secondaryColor;
	if ([([self.prefs objectForKey:@"useCustomFontColor"] ?: @(NO)) boolValue]) {
		secondaryColor = [self colorForKey:@"customFontColor" fallbackColorHex:@"#000000"];
	} else {
		secondaryColor = UIColor.blackColor;
	}

	self.topBar = [[NoteTopBar alloc] initWithFrame:CGRectMake(leftMargin, topMargin, self.frame.size.width - leftMargin - rightMargin, buttonSize) prefs:self.prefs secondaryColor:secondaryColor];
	[self addSubview:self.topBar];
}

- (void)setupTextView {
	// Initialize the text view with a temporary frame; will adjust using auto layout constraints later
	self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) textContainer:nil];
	self.textView.backgroundColor = [UIColor clearColor];

	UIColor *fontColor;
	if ([([self.prefs objectForKey:@"useCustomFontColor"] ?: @(NO)) boolValue]) {
		fontColor = [self colorForKey:@"customFontColor" fallbackColorHex:@"#000000"];
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

	[self addSubview:self.textView];
	NSInteger bottomMargin = [([self.prefs objectForKey:@"textViewBottomMargin"] ?: @0) intValue];
	NSInteger leftMargin = [([self.prefs objectForKey:@"textViewLeftMargin"] ?: @0) intValue];
	NSInteger rightMargin = [([self.prefs objectForKey:@"textViewRightMargin"] ?: @0) intValue];
	self.textView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.textView.topAnchor constraintEqualToAnchor:self.topBar.bottomAnchor].active = YES;
	[self.textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-bottomMargin].active = YES;
	[self.textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:leftMargin].active = YES;
	[self.textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-rightMargin].active = YES;

	[self restoreSavedText];
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
		iconColor = [self colorForKey:@"customFontColor" fallbackColorHex:@"#000000"];
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
	[self.topBar setAlpha:0];
	[self.topBar setHidden:YES];
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

- (void)setTopBarDelegate:(id)delegate {
	self.topBar.delegate = delegate;
}

#pragma mark - Actions

- (void)buttonsBarTapped:(UITapGestureRecognizer *)recognizer {
	if (self.topBar.isHidden) {
		[self showButtons];
		[self startTimer];
	}
}

- (void)didPressBulletButton:(UIButton *)sender {
	[self.textView insertText:@"• "];
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
	if (self.useButtonHiding) {
		self.tapRecognizer.enabled = YES;
	}
	[self.topBar setHidden:self.useButtonHiding];
	[self.privacyView setHidden:YES];
	[self dismissKeyboard];
	[self restoreSavedText];
}

- (void)showPrivacyView {
	if (self.useButtonHiding) {
		self.tapRecognizer.enabled = NO;
	}
	[self.topBar setHidden:YES];
	[self.privacyView setHidden:NO];
	self.textView.text = @"";
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
		[self.topBar setAlpha:0];
	} completion:^(BOOL finished) {
		[self.topBar setHidden:YES];
	}];
}

- (void)showButtons {
	[self.topBar setHidden:NO];
	[UIView animateWithDuration:kDefaultAnimDuration animations:^{
		[self.topBar setAlpha:1.0f];
	} completion:nil];
}

#pragma mark - Private Helpers

- (UIColor *)colorForKey:(NSString *)key fallbackColorHex:(NSString *)fallback {
	NSString *finalColorString = fallback;

	NSDictionary *prefsDict = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/com.gabrielsiu.stickynotecolors.plist"];
	if (prefsDict) {
		NSString *colorString = [prefsDict objectForKey:key] ?: fallback;
		// Remove alpha component from the color string
		NSString *colon = @":";
		finalColorString = [colorString componentsSeparatedByString:colon].firstObject;
	}

	// Convert hex string to UIColor
	// Adapted from https://stackoverflow.com/a/12397366
	unsigned rgbValue = 0;
	NSScanner *scanner = [NSScanner scannerWithString:finalColorString];
	[scanner setScanLocation:1];
	[scanner scanHexInt:&rgbValue];
	return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end