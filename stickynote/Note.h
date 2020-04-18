@interface Note : UIView <UITextViewDelegate> {
    UIButton *clearButton;
    UITextView *textView;
    UIView *privacyView;
    NSDictionary *defaults;
}

- (id)initWithFrame:(CGRect)frame defaults:(NSDictionary *)defaultsDict;
- (void)setTextViewDelegate:(id)delegate;

@end