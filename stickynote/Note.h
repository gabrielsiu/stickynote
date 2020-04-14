@interface Note : UIView <UITextViewDelegate> {
    UIButton *dismissKeyboardButton;
    UIButton *clearButton;
    UITextView *textView;
    UIView *privacyView;
}

- (void)showDismissKeyboardButton;
- (void)hideDismissKeyboardButton;
- (void)setTextViewDelegate:(id)delegate;

@end