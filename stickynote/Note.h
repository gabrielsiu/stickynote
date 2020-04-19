#import <Cephei/HBPreferences.h>

@interface Note : UIView {
    UIButton *clearButton;
    UITextView *textView;
    HBPreferences *prefs;
}

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences;

@end