#import "Constants.h"
#import "Note.h"

@implementation Note

# pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame defaults:(NSDictionary *)defaultsDict {
	self = [super initWithFrame:frame];
	if (self) {
		defaults = defaultsDict;
		[self setupStyle];
		[self setupButtons];
		[self setupTextView];
		// [self setupPrivacyView];
	}
	return self;
}

# pragma mark - Setup

- (void)setupStyle {
	self.backgroundColor = [UIColor yellowColor];
	self.layer.masksToBounds = NO;
	self.layer.shadowOffset = CGSizeMake(-5, 5);
	self.layer.shadowRadius = 5;
	self.layer.shadowOpacity = 0.5;
	NSNumber *defaultsCornerRadius = [defaults valueForKey:@"cornerRadius"];
	self.layer.cornerRadius = defaultsCornerRadius ? defaultsCornerRadius.intValue : kDefaultCornerRadius;
	[self setAlpha:0.8f];
}

- (void)setupButtons {
	dismissKeyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[dismissKeyboardButton setImage:[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-keyboard.png"]] forState:UIControlStateNormal];
	dismissKeyboardButton.frame = CGRectMake(0, 0, kIconSize, kIconSize);
	[dismissKeyboardButton addTarget:self action:@selector(didPressDismissKeyboardButton:) forControlEvents:UIControlEventTouchUpInside];
	[dismissKeyboardButton setHidden:YES];
	[self addSubview:dismissKeyboardButton];

	clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[clearButton setImage:[UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-clear.png"]] forState:UIControlStateNormal];
	clearButton.frame = CGRectMake(self.frame.size.width - kIconSize, 0, kIconSize, kIconSize);
	[clearButton addTarget:self action:@selector(didPressClearButton:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:clearButton];
}


- (void)setupTextView {
	textView = [[UITextView alloc] initWithFrame:CGRectMake(0, kIconSize, 250, self.frame.size.height - kIconSize) textContainer:nil];
	textView.backgroundColor = [UIColor clearColor];
	textView.textColor = [UIColor blackColor];
	NSNumber *defaultsFontSize = [defaults valueForKey:@"fontSize"];
	NSInteger fontSize = defaultsFontSize ? defaultsFontSize.intValue : kDefaultFontSize;
	textView.font = [UIFont systemFontOfSize:fontSize];
	[self addSubview:textView];
}

- (void)setupPrivacyView {
	privacyView = [[UIView alloc] initWithFrame:self.bounds];
	privacyView.backgroundColor = [UIColor blueColor];
	[privacyView setAlpha:1.0f];

	UIImage *lockIcon = [UIImage imageWithContentsOfFile:[kAssetsPath stringByAppendingString:@"/icon-lock.png"]];
	UIImageView *lockIconView = [[UIImageView alloc] initWithImage:lockIcon];
	[privacyView addSubview:lockIconView];
	lockIconView.translatesAutoresizingMaskIntoConstraints = NO;
	[lockIconView.centerXAnchor constraintEqualToAnchor:privacyView.centerXAnchor].active = YES;
	[lockIconView.centerYAnchor constraintEqualToAnchor:privacyView.centerYAnchor].active = YES;

	[self addSubview:privacyView];
}

- (void)setTextViewDelegate:(id)delegate {
	textView.delegate = delegate;
}

# pragma mark - Actions

- (void)didPressDismissKeyboardButton:(UIButton *)sender {
	[textView resignFirstResponder];
}

- (void)didPressClearButton:(UIButton *)sender {
	textView.text = @"";
}

- (void)showDismissKeyboardButton {
	[dismissKeyboardButton setHidden:NO];
}
- (void)hideDismissKeyboardButton {
	[dismissKeyboardButton setHidden:YES];
}

@end