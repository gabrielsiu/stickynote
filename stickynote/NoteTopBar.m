#import "HBPreferences+Helpers.h"
#import "Constants.h"
#import "NoteTopBar.h"

@interface NoteTopBar ()
@property (nonatomic) BOOL noteLocked;
@property (nonatomic) NSInteger buttonSize;
@property (nonatomic, strong) UIColor *secondaryColor;
@property (nonatomic, strong) HBPreferences *prefs;
@property (nonatomic, strong) UIButton *lockButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *clearButton;
@end

@implementation NoteTopBar

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences secondaryColor:(UIColor *)color {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = UIColor.clearColor;
		self.secondaryColor = color;
		self.prefs = preferences;
		[self getPreferenceValues];
		[self setupNavigationBar];
		[self setupButtons];

		// Set up optional header text
		if ([([self.prefs objectForKey:@"useHeaderText"] ?: @(NO)) boolValue]) {
			[self setupHeaderText];
		}
	}
	return self;
}

#pragma mark - Setup

- (void)getPreferenceValues {
	// Determine top button size
	if ([([self.prefs objectForKey:@"useCustomTopButtonSize"] ?: @(NO)) boolValue]) {
		self.buttonSize = [self.prefs nonZeroIntegerForKey:@"topButtonSize" fallback:kIconSize];
	} else {
		self.buttonSize = kIconSize;
	}
}

- (void)setupNavigationBar {
	// Set up navigation bar for the buttons
	UINavigationBar *buttonsBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
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
	[self addSubview:buttonsBar];
	[buttonsBar.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
	[buttonsBar.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
	[buttonsBar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
	[buttonsBar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
}

- (void)setupButtons {
	// Lock Button
	self.lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self setLockImage:([[NSUserDefaults standardUserDefaults] boolForKey:@"stickynote_locked"] ?: NO)];
	[self.lockButton addTarget:self action:@selector(didPressLockButton:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.lockButton];
	self.lockButton.tintColor = self.secondaryColor;
	self.lockButton.translatesAutoresizingMaskIntoConstraints = NO;
	[self.lockButton.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
	[self.lockButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
	[self.lockButton.widthAnchor constraintEqualToConstant:self.buttonSize].active = YES;
	[self.lockButton.heightAnchor constraintEqualToConstant:self.buttonSize].active = YES;
	// Share Button
	if ([([self.prefs objectForKey:@"allowSharing"] ?: @(NO)) boolValue]) {
		self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[self.shareButton setImage:[[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-share.png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
		[self.shareButton addTarget:self action:@selector(didPressShareButton:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:self.shareButton];
		self.shareButton.tintColor = self.secondaryColor;
		self.shareButton.translatesAutoresizingMaskIntoConstraints = NO;
		[self.shareButton.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
		[self.shareButton.leadingAnchor constraintEqualToAnchor:self.lockButton.trailingAnchor].active = YES;
		[self.shareButton.widthAnchor constraintEqualToConstant:self.buttonSize].active = YES;
		[self.shareButton.heightAnchor constraintEqualToConstant:self.buttonSize].active = YES;
	}
	// Clear Button
	self.clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.clearButton setImage:[[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-clear.png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	[self.clearButton addTarget:self action:@selector(didPressClearButton:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.clearButton];
	self.clearButton.tintColor = self.secondaryColor;
	self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
	[self.clearButton.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
	[self.clearButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
	[self.clearButton.widthAnchor constraintEqualToConstant:self.buttonSize].active = YES;
	[self.clearButton.heightAnchor constraintEqualToConstant:self.buttonSize].active = YES;
}

- (void)setupHeaderText {
	UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width - 2*self.buttonSize, self.frame.size.height)];
	headerLabel.textAlignment = NSTextAlignmentCenter;
	headerLabel.textColor = self.secondaryColor;
	headerLabel.text = [self.prefs objectForKey:@"headerText"] ?: @"";
	if ([([self.prefs objectForKey:@"useCustomFont"] ?: @(NO)) boolValue]) {
		NSInteger headerFontSize;
		if ([self.prefs valueExistsForKey:@"headerFontSize"]) {
			headerFontSize = [([self.prefs objectForKey:@"headerFontSize"] ?: @(kDefaultFontSize)) intValue];
		} else {
			headerFontSize = kDefaultFontSize;
		}
		NSString *fontName = [self.prefs objectForKey:@"customFont"] ?: @"";
		if (![fontName isEqualToString:@""]) {
			headerLabel.font = [UIFont fontWithName:fontName size:headerFontSize];
		} else {
			headerLabel.font = [UIFont systemFontOfSize:headerFontSize];
		}
	} else {
		headerLabel.font = [UIFont systemFontOfSize:kDefaultFontSize];
	}

	[self addSubview:headerLabel];
	headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[headerLabel.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
	[headerLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
	if (self.shareButton) {
		[headerLabel.leadingAnchor constraintEqualToAnchor:self.shareButton.trailingAnchor].active = YES;
	} else {
		[headerLabel.leadingAnchor constraintEqualToAnchor:self.lockButton.trailingAnchor].active = YES;
	}
	[headerLabel.trailingAnchor constraintEqualToAnchor:self.clearButton.leadingAnchor].active = YES;
}

#pragma mark - Actions

- (void)didPressLockButton:(UIButton *)sender {
	self.noteLocked = !self.noteLocked;
	[self setLockImage:self.noteLocked];
	[[NSUserDefaults standardUserDefaults] setBool:self.noteLocked forKey:@"stickynote_locked"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self.delegate didPressLockButton:self.noteLocked];
}

- (void)didPressShareButton:(UIButton *)sender {
	[self.delegate didPressShareButton:self];
}

- (void)didPressClearButton:(UIButton *)sender {
	[self.delegate didPressClearButton:self];
}

#pragma mark - Private Helpers

- (void)setLockImage:(BOOL)locked {
	NSString *imageName;
	if (locked) {
		imageName = @"/icon-lock.png";
	} else {
		imageName = @"/icon-unlock.png";
	}
	[self.lockButton setImage:[[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:imageName]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
}

@end