@interface Note : UIView {
    UIButton *clearButton;
    UITextView *textView;
    NSDictionary *defaults;
}

- (id)initWithFrame:(CGRect)frame defaults:(NSDictionary *)defaultsDict;

@end