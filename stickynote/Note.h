#import <Cephei/HBPreferences.h>
#import "NoteTopBar.h"

@interface Note : UIView

@property (nonatomic, strong) NoteTopBar *topBar;

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences useButtonHiding:(BOOL)useButtonHiding;
- (void)setTextViewDelegate:(id)delegate;
- (void)setTopBarDelegate:(id)delegate;
- (void)saveText;
- (void)clearTextView;
- (NSString *)getText;
- (BOOL)privacyViewIsHidden;
- (void)hidePrivacyView;
- (void)showPrivacyView;
- (void)startTimer;
- (void)stopTimer;
- (void)showButtons;

@end