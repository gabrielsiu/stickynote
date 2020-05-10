#import <Cephei/HBPreferences.h>

@class Note;
@protocol ButtonActionDelegate <NSObject>
- (void)didPressShareButton:(Note *)sender;
- (void)didPressClearButton:(Note *)sender;
@end

@interface Note : UIView

@property (nonatomic, weak) id <ButtonActionDelegate> delegate;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;
@property (nonatomic, strong) UIBarButtonItem *clearButtonItem;

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences useButtonHiding:(BOOL)useButtonHiding;
- (void)setTextViewDelegate:(id)delegate;
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