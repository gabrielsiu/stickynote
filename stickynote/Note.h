@interface Note : UIView {
    UIButton *clearButton;
    UITextView *textView;
    UIView *privacyView;
    NSDictionary *defaults;
}

- (id)initWithFrame:(CGRect)frame defaults:(NSDictionary *)defaultsDict;

@end