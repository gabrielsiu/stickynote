#import "Note.h"

@interface NoteViewController : UIViewController <UITextViewDelegate, ButtonActionDelegate>

@property (nonatomic, strong) Note *noteView;
- (id)initWithPrefs:(HBPreferences *)preferences screenSize:(CGSize)size;

@end