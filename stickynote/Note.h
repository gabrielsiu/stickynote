#import <Cephei/HBPreferences.h>

@interface Note : UIView {
    UIButton *clearButton;
    UITextView *textView;
    HBPreferences *prefs;
    UIView *privacyView;
}

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences;
- (void)setTextViewDelegate:(id)delegate;
- (void)saveText;
- (void)hidePrivacyView;
- (void)showPrivacyView;

@end