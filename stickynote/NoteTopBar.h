#import <Cephei/HBPreferences.h>

@class NoteTopBar;
@protocol ButtonActionDelegate <NSObject>
- (void)didPressLockButton:(BOOL)locked;
- (void)didPressShareButton:(NoteTopBar *)sender;
- (void)didPressClearButton:(NoteTopBar *)sender;
@end

@interface NoteTopBar : UIView

@property (nonatomic, weak) id <ButtonActionDelegate> delegate;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;
@property (nonatomic, strong) UIBarButtonItem *clearButtonItem;

- (id)initWithFrame:(CGRect)frame prefs:(HBPreferences *)preferences secondaryColor:(UIColor *)color;

@end