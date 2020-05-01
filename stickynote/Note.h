#import <Cephei/HBPreferences.h>

@interface Note : UIView {
    UIButton *clearButton;
    UITextView *textView;
    HBPreferences *prefs;
    BOOL deviceIsLocked;
    UIView *privacyView;
}

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences locked:(BOOL)locked;
- (void)setTextViewDelegate:(id)delegate;
- (void)saveText;

@end