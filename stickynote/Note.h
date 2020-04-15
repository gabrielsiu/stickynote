@interface Note : UIView <UITextViewDelegate> {
    UIButton *dismissKeyboardButton;
    UIButton *clearButton;
    UITextView *textView;
    UIView *privacyView;
    NSDictionary *defaults;
}

- (id)initWithFrame:(CGRect)frame defaults:(NSDictionary *)defaultsDict;
- (void)showDismissKeyboardButton;
- (void)hideDismissKeyboardButton;
- (void)setTextViewDelegate:(id)delegate;

@end